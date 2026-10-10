import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'bloc/contacts_cubit.dart';
import 'group_setup_screen.dart';
import 'widgets/chat_widgets.dart';

class MemberPickerScreen extends StatelessWidget {
  const MemberPickerScreen({
    super.key,
    required this.title,
    required this.multi,
    this.showGroupAction = false,
    this.excludeIds = const {},
    this.submitLabel = 'Next',
    this.onSubmit,
  });

  final String title;
  final bool multi;
  final bool showGroupAction;
  final Set<String> excludeIds;
  final String submitLabel;
  final Future<void> Function(BuildContext context, List<ChatUser> users)? onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactsCubit(context.read<ChatRepository>())..load(),
      child: _PickerView(config: this),
    );
  }
}

class _PickerView extends StatefulWidget {
  const _PickerView({required this.config});
  final MemberPickerScreen config;
  @override
  State<_PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends State<_PickerView> {
  final _searchCtrl = TextEditingController();
  final Map<String, ChatUser> _selected = {};
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  MemberPickerScreen get _c => widget.config;

  void _toggle(ChatUser u) {
    setState(() {
      if (_selected.containsKey(u.id)) {
        _selected.remove(u.id);
      } else {
        _selected[u.id] = u;
      }
    });
  }

  Future<void> _submit() async {
    final users = _selected.values.toList();
    if (users.isEmpty) return;
    if (_c.onSubmit != null) {
      await _c.onSubmit!(context, users);
    } else {
      Navigator.of(context).pop(users);
    }
  }

  Future<void> _newGroup() async {
    final created = await Navigator.of(context).push<Conversation>(
      MaterialPageRoute(builder: (_) => const GroupFlow()),
    );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthRepository>().currentUser?.id ?? '';
    final hidden = {..._c.excludeIds, myId};
    return Scaffold(
      appBar: AppBar(
        title: Text(_c.title),
        actions: [
          if (_c.multi)
            TextButton(
              onPressed: _selected.isEmpty ? null : _submit,
              child: Text(
                _selected.isEmpty ? _c.submitLabel : '${_c.submitLabel} (${_selected.length})',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: context.read<ContactsCubit>().onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final u in _selected.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InputChip(
                        label: Text(u.name),
                        onDeleted: () => _toggle(u),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<ContactsCubit, ContactsState>(
              builder: (context, s) {
                final searching = s.query.length >= 2;
                final source = searching ? s.searchResults : s.phoneContacts;
                final users = source.where((u) => !hidden.contains(u.id)).toList();
                final header = <Widget>[];
                if (!_c.multi && _c.showGroupAction && !searching) {
                  header.add(ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.group_add, color: Colors.white),
                    ),
                    title: const Text('New group'),
                    onTap: _newGroup,
                  ));
                }

                Widget body;
                if (!searching && s.status == ContactsStatus.loading) {
                  body = const Center(child: CircularProgressIndicator());
                } else if (searching && s.searching && users.isEmpty) {
                  body = const Center(child: CircularProgressIndicator());
                } else if (users.isEmpty) {
                  body = _EmptyState(state: s, searching: searching);
                } else {
                  body = ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final checked = _selected.containsKey(u.id);
                      return ListTile(
                        leading: ChatAvatar(name: u.name),
                        title: Text(u.name),
                        subtitle: u.email.isEmpty
                            ? null
                            : Text(
                                u.email,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                        trailing: _c.multi
                            ? Checkbox(
                                value: checked,
                                onChanged: (_) => _toggle(u),
                              )
                            : null,
                        onTap: () {
                          if (_c.multi) {
                            _toggle(u);
                          } else {
                            Navigator.of(context).pop(<ChatUser>[u]);
                          }
                        },
                      );
                    },
                  );
                }
                return Column(
                  children: [...header, Expanded(child: body)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state, required this.searching});
  final ContactsState state;
  final bool searching;
  @override
  Widget build(BuildContext context) {
    String text;
    bool retry = false;
    if (searching) {
      text = 'No one found for "${state.query}".';
    } else if (state.status == ContactsStatus.permissionDenied) {
      text = 'Allow contacts access to see which of your contacts are on '
          'Quorum. You can still search by name or email.';
      retry = true;
    } else if (state.status == ContactsStatus.failure) {
      text = state.error ?? 'Could not load your contacts.';
      retry = true;
    } else {
      text = 'Try searching by name or email.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (retry) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: context.read<ContactsCubit>().load,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}