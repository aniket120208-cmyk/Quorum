import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/chat_repository.dart';
import 'package:quorum/utils/uuid.dart';

enum ChatRoomStatus { loading, ready, failure }

class ChatRoomState {
  const ChatRoomState({
    this.status = ChatRoomStatus.loading,
    this.messages = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.typingUserIds = const {},
    this.otherReadMessageId,
    this.error,
  });

  final List<ChatMessage> messages;
  final ChatRoomStatus status;
  final bool hasMore;
  final bool loadingMore;
  final Set<String> typingUserIds;
  final String? otherReadMessageId;
  final String? error;

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    List<ChatMessage>? messages,
    bool? hasMore,
    bool? loadingMore,
    Set<String>? typingUserIds,
    String? otherReadMessageId,
    String? error,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      otherReadMessageId: otherReadMessageId ?? this.otherReadMessageId,
      error: error,
    );
  }
}

class ChatRoomCubit extends Cubit<ChatRoomState> {
  ChatRoomCubit({
    required ChatRepository repo,
    required ChatSocketService socket,
    required this.conversationId,
    required this.myId,
    required this.myName,
    String? initialOtherReadMessageId,
  })  : _repo = repo,
        _socket = socket,
        super(ChatRoomState(otherReadMessageId: initialOtherReadMessageId));

  static const _pageSize = 20;
  static const _syncSize = 50;
  static const _typingIdle = Duration(seconds: 2);
  static const _typingExpiry = Duration(seconds: 6);
  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String conversationId;
  final String myId;
  final String myName;

  final List<StreamSubscription<dynamic>> _subs = [];
  final Map<String, Timer> _remoteTyping = {};
  Timer? _typingIdleTimer;
  String? _nextCursor;
  String? _lastReadReported;
  bool _typingSent = false;
  bool _syncing = false;

  Future<void> start() async {
    if (_subs.isEmpty) _subscribe();
    _socket.joinConversation(conversationId);
    _socket.connect();

    if (state.status != ChatRoomStatus.loading) {
      emit(state.copyWith(status: ChatRoomStatus.loading));
    }

    try {
      final page = await _repo.fetchMessages(conversationId, limit: _pageSize);
      if (isClosed) return;
      _nextCursor = page.nextCursor;
      emit(state.copyWith(
        status: ChatRoomStatus.ready,
        messages: _merge(state.messages, page.messages),
        hasMore: page.hasNextPage,
      ));
      _reportRead();
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: ChatRoomStatus.failure, error: '$e'));
      }
    }
  }

  void _subscribe() {
    _subs.addAll([
      _socket.messageNew.listen(_onNewMessage),
      _socket.typing.listen(_onTyping),
      _socket.reads.listen(_onRead),
      _socket.connection.listen((connected) {
        if (connected) _sync();
      }),
    ]);
  }

  void _onNewMessage(ChatMessage m) {
    if (m.conversationId != conversationId) return;
    emit(state.copyWith(messages: _merge(state.messages, [m])));
    if (m.senderId != myId) {
      _clearRemoteTyping(m.senderId);
      _reportRead();
    }
  }

  void _onTyping(TypingEvent e) {
    if (e.conversationId != conversationId || e.userId == myId) return;
    _remoteTyping.remove(e.userId)?.cancel();
    final next = {...state.typingUserIds};
    if (e.isTyping) {
      next.add(e.userId);
      _remoteTyping[e.userId] = Timer(_typingExpiry, () => _clearRemoteTyping(e.userId));
    } else {
      next.remove(e.userId);
    }
    emit(state.copyWith(typingUserIds: next));
  }

  void _clearRemoteTyping(String userId) {
    _remoteTyping.remove(userId)?.cancel();
    if (isClosed || !state.typingUserIds.contains(userId)) return;
    emit(state.copyWith(
      typingUserIds: {...state.typingUserIds}..remove(userId),
    ));
  }

  void _onRead(ReadEvent e) {
    if (e.conversationId != conversationId || e.userId == myId) return;
    final id = e.messageId;
    if (id == null) return;
    emit(state.copyWith(otherReadMessageId: id));
  }

  Future<void> _sync() async {
    if (_syncing || isClosed || state.status != ChatRoomStatus.ready) return;
    _syncing = true;
    try {
      final page = await _repo.fetchMessages(conversationId, limit: _syncSize);
      if (isClosed) return;
      emit(state.copyWith(messages: _merge(state.messages, page.messages)));
      _lastReadReported = null;
      _reportRead();
    } catch (_) {
    } finally {
      _syncing = false;
    }
  }

  void _reportRead() {
    for (final m in state.messages) {
      if (m.senderId == myId || m.id == null) continue;
      if (m.id != _lastReadReported &&
          _socket.markRead(conversationId, m.id!)) {
        _lastReadReported = m.id;
      }
      return; 
    }
  }

  void onInputChanged(String text) {
    if (text.trim().isEmpty) {
      stopTyping();
      return;
    }
    if (!_typingSent) {
      _typingSent = true;
      _socket.sendTyping(conversationId, typing: true);
    }
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(_typingIdle, stopTyping);
  }

  void stopTyping() {
    _typingIdleTimer?.cancel();
    if (_typingSent) {
      _typingSent = false;
      _socket.sendTyping(conversationId, typing: false);
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (state.loadingMore || !state.hasMore || cursor == null) return;

    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetchMessages(
        conversationId,
        cursor: cursor,
        limit: _pageSize,
      );
      if (isClosed) return;
      _nextCursor = page.nextCursor;
      emit(state.copyWith(
        loadingMore: false,
        hasMore: page.hasNextPage,
        messages: _merge(state.messages, page.messages),
      ));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    stopTyping();
    final pending = _newPending(text: trimmed);
    emit(state.copyWith(messages: _merge(state.messages, [pending])));
    await _deliver(pending);
  }

  Future<void> sendMedia(String localPath, {String fileType = 'image'}) async {
    stopTyping();
    final pending = _newPending(fileUrl: localPath, fileType: fileType);
    emit(state.copyWith(messages: _merge(state.messages, [pending])));
    await _deliver(pending);
  }

  Future<void> retry(ChatMessage failed) async {
    if (failed.status != MessageStatus.failed) return;
    final again = failed.copyWith(status: MessageStatus.sending);
    emit(state.copyWith(messages: _merge(state.messages, [again])));
    await _deliver(again);
  }

  ChatMessage _newPending({
    String text = '',
    String? fileUrl,
    String? fileType,
  }) {
    return ChatMessage(
      id: null,
      clientId: uuidV4(), 
      conversationId: conversationId,
      senderId: myId,
      senderName: myName,
      text: text,
      fileUrl: fileUrl,
      fileType: fileType,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  Future<void> _deliver(ChatMessage pending) async {
    var current = pending;
    try {
      final url = current.fileUrl;
      if (url != null && !url.startsWith('http')) {
        final uploaded = await _repo.uploadMedia(url);
        current = current.copyWith(fileUrl: uploaded);
        if (!isClosed) {
          emit(state.copyWith(messages: _merge(state.messages, [current])));
        }
      }

      final sent = await _socket.sendMessage(
        conversationId: conversationId,
        clientMessageId: current.clientId!,
        content: current.text,
        fileUrl: current.fileUrl,
        fileType: current.fileType,
      );
      if (!isClosed) {
        emit(state.copyWith(messages: _merge(state.messages, [sent])));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          messages: _merge(
            state.messages,
            [current.copyWith(status: MessageStatus.failed)],
          ),
        ));
      }
    }
  }

  List<ChatMessage> _merge(
    List<ChatMessage> existing,
    List<ChatMessage> incoming,
  ) {
    final result = List<ChatMessage>.from(existing);
    for (final m in incoming) {
      final before = result.length;
      result.removeWhere((x) =>
          (m.id != null && x.id == m.id) ||
          (m.clientId != null && x.clientId == m.clientId));
      final replaced = result.length != before;

      if (!replaced && m.id != null && m.senderId == myId) {
        final i = result.lastIndexWhere((x) =>
            x.id == null &&
            x.senderId == myId &&
            x.text == m.text &&
            x.fileType == m.fileType);
        if (i != -1) result.removeAt(i);
      }
      result.add(m);
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> close() {
    stopTyping();
    _socket.leaveConversation(conversationId);
    for (final s in _subs) {
      s.cancel();
    }
    for (final t in _remoteTyping.values) {
      t.cancel();
    }
    return super.close();
  }
}