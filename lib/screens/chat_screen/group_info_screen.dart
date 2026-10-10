import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'member_picker_screen.dart';
import 'widgets/chat_widgets.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.conversation});
  final Conversation conversation;
  static const left = 'left';
  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Conversation _c = widget.conversation;
  bool _busy = false;
  ChatRepository get _repo => context.read<ChatRepository>();
  String get _myId => context.read<AuthRepository>().currentUser?.id ?? '';
  bool get _isOwner => _c.createdBy == _myId;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename() async {
    final ctrl = TextEditingController(text: _c.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Group name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || name == _c.name) return;
    await _run(() async {
      final updated = await _repo.renameGroup(_c.id, name);
      if (mounted) setState(() => _c = updated);
    });
  }

  Future<void> _addMembers() async {
    final picked = await Navigator.of(context).push<List<ChatUser>>(
      MaterialPageRoute(
        builder: (_) => MemberPickerScreen(
          title: 'Add members',
          multi: true,
          submitLabel: 'Add',
          excludeIds: _c.members.map((m) => m.id).toSet(),
        ),
      ),
    );
    if (picked == null || picked.isEmpty) return;
    await _run(() async {
      final updated =
          await _repo.addMembers(_c.id, picked.map((u) => u.id).toList());
      if (mounted) setState(() => _c = updated);
    });
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _remove(ChatUser u) async {
    if (!await _confirm('Remove ${u.name}?',
        'They will no longer see new messages in this group.', 'Remove')) {
      return;
    }
    await _run(() async {
      await _repo.removeMember(_c.id, u.id);
      final updated = await _repo.fetchConversation(_c.id);
      if (mounted) setState(() => _c = updated);
    });
  }

  Future<void> _leave() async {
    if (!await _confirm(
        'Leave group?', 'You will stop receiving messages from it.', 'Leave')) {
      return;
    }
    await _run(() async {
      await _repo.leaveGroup(_c.id);
      if (mounted) Navigator.of(context).pop(GroupInfoScreen.left);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_c);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Group info')),
        body: ListView(
          children: [
            const SizedBox(height: 24),
            Center(child: ChatAvatar(name: _c.name, isGroup: true, radius: 44)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _c.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Center(
              child: Text(
                '${_c.members.length} members',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            if (_isOwner)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rename group'),
                onTap: _rename,
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Add members'),
              onTap: _addMembers,
            ),
            const Divider(color: AppColors.surfaceBorder),
            for (final m in _c.members)
              ListTile(
                leading: ChatAvatar(name: m.name),
                title: Text(m.id == _myId ? '${m.name} (You)' : m.name),
                subtitle: m.id == _c.createdBy
                    ? const Text(
                        'Admin',
                        style: TextStyle(color: AppColors.primaryLight),
                      )
                    : null,
                trailing: _isOwner && m.id != _myId
                    ? IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _remove(m),
                      )
                    : null,
              ),
            const Divider(color: AppColors.surfaceBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Leave group',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: _leave,
            ),
          ],
        ),
      ),
    );
  }
}