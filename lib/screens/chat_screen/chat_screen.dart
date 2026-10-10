import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'bloc/chat_list_cubit.dart';
import 'chat_room_screen.dart';
import 'group_setup_screen.dart';
import 'member_picker_screen.dart';
import 'widgets/chat_widgets.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthRepository>().currentUser?.id ?? '';
    return BlocProvider(
      create: (context) => ChatListCubit(
        context.read<ChatRepository>(),
        context.read<ChatSocketService>(),
        myId: myId,
      )..start(),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();
  Future<void> _openRoom(BuildContext context, Conversation c) async {
    final cubit = context.read<ChatListCubit>();
    cubit.activeConversationId = c.id;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: c)),
    );
    cubit.activeConversationId = null;
    if (!cubit.isClosed) cubit.refresh();
  }

  Future<void> _newChat(BuildContext context) async {
    final repo = context.read<ChatRepository>();
    final picked = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => const MemberPickerScreen(
          title: 'New chat',
          multi: false,
          showGroupAction: true,
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked is Conversation) {
      await _openRoom(context, picked);
      return;
    }
    if (picked is! List<ChatUser> || picked.isEmpty) return;
    try {
      final conversation = await repo.openDirect(picked.first.id);
      if (context.mounted) await _openRoom(context, conversation);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthRepository>().currentUser?.id ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            tooltip: 'New group',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () async {
              final created = await Navigator.of(context).push<Conversation>(
                MaterialPageRoute(
                  builder: (_) => const GroupFlow(),
                ),
              );
              if (created != null && context.mounted) {
                await _openRoom(context, created);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        tooltip: 'New chat',
        onPressed: () => _newChat(context),
        child: const Icon(Icons.edit_outlined),
      ),
      body: BlocBuilder<ChatListCubit, ChatListState>(
        builder: (context, s) {
          if (s.status == ChatListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.status == ChatListStatus.failure) {
            return _Message(
              icon: Icons.cloud_off,
              text: s.error ?? 'Could not load chats.',
              actionLabel: 'Retry',
              onAction: () =>
                  context.read<ChatListCubit>().refresh(showLoading: true),
            );
          }
          if (s.conversations.isEmpty) {
            return _Message(
              icon: Icons.chat_bubble_outline,
              text: 'No conversations yet.\nStart one with your contacts.',
              actionLabel: 'New chat',
              onAction: () => _newChat(context),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<ChatListCubit>().refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: s.conversations.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 76,
                color: AppColors.surfaceBorder,
              ),
              itemBuilder: (context, i) {
                final c = s.conversations[i];
                return _ConversationTile(
                  conversation: c,
                  myId: myId,
                  onTap: () => _openRoom(context, c),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  final Conversation conversation;
  final String myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = conversation.titleFor(myId);
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    String preview = 'No messages yet';
    if (last != null) {
      final mine = last.senderId == myId;
      final prefix = mine
          ? 'You: '
          : (conversation.isGroup && last.senderName.isNotEmpty
              ? '${last.senderName}: '
              : '');
      preview = '$prefix${last.previewText}';
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ChatAvatar(name: title, isGroup: conversation.isGroup),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatListTime(last?.createdAt ?? conversation.updatedAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}