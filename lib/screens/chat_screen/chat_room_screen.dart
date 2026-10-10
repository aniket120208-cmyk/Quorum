import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/main.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'bloc/chat_room_cubit.dart';
import 'chat_search_screen.dart';
import 'group_info_screen.dart';
import 'widgets/chat_widgets.dart';

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key, required this.conversation});
  final Conversation conversation;
  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthRepository>().currentUser;
    final myId = me?.id ?? '';
    return BlocProvider(
      create: (context) => ChatRoomCubit(
        repo: context.read<ChatRepository>(),
        socket: context.read<ChatSocketService>(),
        conversationId: conversation.id,
        myId: myId,
        myName: me?.name ?? '',
        initialOtherReadMessageId:
            conversation.otherMember(myId)?.lastReadMessageId,
      )..start(),
      child: _RoomView(conversation: conversation, myId: myId),
    );
  }
}

class _RoomView extends StatefulWidget {
  const _RoomView({required this.conversation, required this.myId});
  final Conversation conversation;
  final String myId;
  @override
  State<_RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<_RoomView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late Conversation _conversation = widget.conversation;
  late final ChatRoomCubit _cubit = context.read<ChatRoomCubit>();
  String _lastText = '';
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.extentAfter < 200) _cubit.loadMore();
    });
    _inputCtrl.addListener(() {
      if (_inputCtrl.text == _lastText) return;
      _lastText = _inputCtrl.text;
      _cubit.onInputChanged(_lastText);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _cubit.send(text);
    _inputCtrl.clear();
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  Future<void> _attach() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;
      _cubit.sendMedia(picked.path, fileType: 'image');
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not open that photo.');
    }
  }

  void _openSearch(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatSearchScreen(
          conversationId: _conversation.id,
          title: title,
          repo: context.read<ChatRepository>(),
        ),
      ),
    );
  }

  Future<void> _openInfo() async {
    if (!_conversation.isGroup) return;
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => GroupInfoScreen(conversation: _conversation),
      ),
    );
    if (!mounted) return;
    if (result == GroupInfoScreen.left) {
      Navigator.of(context).pop();
    } else if (result is Conversation) {
      setState(() => _conversation = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _conversation.titleFor(widget.myId);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openInfo,
          child: Row(
            children: [
              ChatAvatar(
                name: title,
                isGroup: _conversation.isGroup,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17),
                    ),
                    _Subtitle(conversation: _conversation, myId: widget.myId),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search messages',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(title),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ConnectionBanner(),
          Expanded(
            child: BlocBuilder<ChatRoomCubit, ChatRoomState>(
              builder: (context, s) {
                if (s.status == ChatRoomStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.status == ChatRoomStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.error ?? 'Could not load messages.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _cubit.start,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (s.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  );
                }
                final msgs = s.messages;
                DateTime? readUpTo;
                if (s.otherReadMessageId != null) {
                  for (final m in msgs) {
                    if (m.id == s.otherReadMessageId) {
                      readUpTo = m.createdAt;
                      break;
                    }
                  }
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: msgs.length + (s.loadingMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == msgs.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final m = msgs[i];
                    final older = i + 1 < msgs.length ? msgs[i + 1] : null;
                    final newer = i > 0 ? msgs[i - 1] : null;
                    final showDay = older == null || !sameDay(older.createdAt, m.createdAt);
                    final mine = m.senderId == widget.myId;
                    final startsRun = older == null ||
                        showDay ||
                        older.senderId != m.senderId;
                    final endsRun = newer == null || newer.senderId != m.senderId;
                    final isRead = mine &&
                        m.status == MessageStatus.sent &&
                        readUpTo != null &&
                        !m.createdAt.isAfter(readUpTo);

                    return Column(
                      key: ValueKey(m.clientId ?? m.id ?? i),
                      children: [
                        if (showDay) _DayChip(label: formatDayLabel(m.createdAt)),
                        _MessageBubble(
                          message: m,
                          isMe: mine,
                          isRead: isRead,
                          showSender:
                              _conversation.isGroup && !mine && startsRun,
                          showTime: endsRun,
                          onRetry: m.status == MessageStatus.failed
                              ? () => _cubit.retry(m)
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    color: AppColors.textSecondary,
                    tooltip: 'Attach photo',
                    onPressed: _attach,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primaryLight,
                    tooltip: 'Send',
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.conversation, required this.myId});
  final Conversation conversation;
  final String myId;
  Widget _line(String text, {Color color = AppColors.textSecondary}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.read<ChatSocketService>();
    return BlocBuilder<ChatRoomCubit, ChatRoomState>(
      buildWhen: (a, b) => a.typingUserIds != b.typingUserIds,
      builder: (context, s) {
        if (s.typingUserIds.isNotEmpty) {
          return _line('typing…', color: AppColors.primaryLight);
        }
        if (conversation.isGroup) {
          return _line('${conversation.members.length} members');
        }
        final other = conversation.otherMember(myId);
        if (other == null) return const SizedBox.shrink();

        return StreamBuilder<PresenceEvent>(
          stream: socket.presence,
          builder: (context, _) {
            if (socket.isOnline(other.id)) {
              return _line('online', color: Colors.greenAccent);
            }
            final seen = socket.lastSeen(other.id);
            if (seen != null) return _line('last seen ${formatLastSeen(seen)}');
            return other.email.isEmpty
                ? const SizedBox.shrink()
                : _line(other.email);
          },
        );
      },
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner();
  @override
  Widget build(BuildContext context) {
    final socket = context.read<ChatSocketService>();
    return StreamBuilder<bool>(
      stream: socket.connection,
      initialData: socket.isConnected,
      builder: (context, snap) {
        if (snap.data == true) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.surfaceBorder,
          child: const Text(
            'Connecting…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isRead,
    required this.showSender,
    required this.showTime,
    this.onRetry,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isRead;
  final bool showSender;
  final bool showTime;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.status == MessageStatus.failed;
    final sending = message.status == MessageStatus.sending;
    final hasText = message.text.trim().isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onRetry,
            child: Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.surfaceBorder),
              ),
              child: Opacity(
                opacity: sending ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSender && message.senderName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (message.hasMedia) ...[
                      _MediaView(message: message),
                      if (hasText) const SizedBox(height: 6),
                    ],
                    if (hasText)
                      Text(
                        message.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (failed)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Not sent. Tap to retry',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            )
          else if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sending ? 'Sending…' : formatClock(message.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe && !sending) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? AppColors.primaryLight : AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaView extends StatelessWidget {
  const _MediaView({required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final url = message.fileUrl!;
    if (message.fileType == 'image') {
      final isLocal = !url.startsWith('http');
      final image = isLocal
          ? Image.file(File(url), fit: BoxFit.cover)
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 160,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, _, _) => const SizedBox(
                height: 80,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
            );
      return GestureDetector(
        onTap: isLocal
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => _ImageViewer(url: url)),
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: image,
          ),
        ),
      );
    }

    final (icon, label) = switch (message.fileType) {
      'video' => (Icons.videocam_outlined, 'Video'),
      'audio' => (Icons.audiotrack_outlined, 'Audio'),
      _ => (Icons.insert_drive_file_outlined, 'File'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }
}