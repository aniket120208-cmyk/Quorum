import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'member_picker_screen.dart';
import 'widgets/chat_widgets.dart';

class GroupFlow extends StatelessWidget {
  const GroupFlow({super.key});
  @override
  Widget build(BuildContext context) {
    return MemberPickerScreen(
      title: 'Add members',
      multi: true,
      onSubmit: (ctx, users) async {
        final conversation = await Navigator.of(ctx).push<Conversation>(
          MaterialPageRoute(builder: (_) => GroupSetupScreen(members: users)),
        );
        if (conversation != null && ctx.mounted) {
          Navigator.of(ctx).pop(conversation);
        }
      },
    );
  }
}

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key, required this.members});
  final List<ChatUser> members;
  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final conversation = await context.read<ChatRepository>().createGroup(
            name: name,
            memberIds: widget.members.map((m) => m.id).toList(),
          );
      if (mounted) Navigator.of(context).pop(conversation);
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        showErrorSnack(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _create(),
            decoration: InputDecoration(
              labelText: 'Group name',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.members.length} '
            'member${widget.members.length == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final m in widget.members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ChatAvatar(name: m.name),
              title: Text(m.name),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _nameCtrl.text.trim().isEmpty || _creating
                ? null
                : _create,
            child: _creating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create group'),
          ),
        ],
      ),
    );
  }
}