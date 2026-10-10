import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/chat_socket_service.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/chat_repository.dart';

enum ChatListStatus { loading, ready, failure }

class ChatListState {
  const ChatListState({
    this.status = ChatListStatus.loading,
    this.conversations = const [],
    this.error,
  });

  final ChatListStatus status;
  final List<Conversation> conversations;
  final String? error;
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this._repo, this._socket, {required this.myId})
      : super(const ChatListState());

  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String myId;
  static const _backgroundRefresh = Duration(seconds: 30);

  Timer? _timer;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ConversationUpdateEvent>? _updateSub;
  StreamSubscription<bool>? _connectionSub;
  bool _busy = false;
  bool _wasConnected = false;
  String? activeConversationId;

  Future<void> start() async {
    _socket.connect();
    _messageSub ??= _socket.messageNew.listen(_onMessage);
    _updateSub ??= _socket.conversationUpdates.listen(_onUpdate);
    _connectionSub ??= _socket.connection.listen((connected) {
      if (connected && _wasConnected) refresh();
      _wasConnected = _wasConnected || connected;
    });

    await refresh(showLoading: true);
    _timer?.cancel();
    _timer = Timer.periodic(_backgroundRefresh, (_) => refresh());
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (_busy || isClosed) return;
    _busy = true;
    if (showLoading) emit(const ChatListState());
    try {
      final list = await _repo.fetchConversations();
      if (!isClosed) {
        emit(ChatListState(status: ChatListStatus.ready, conversations: list));
      }
    } catch (e) {
      if (!isClosed && state.status != ChatListStatus.ready) {
        emit(ChatListState(
          status: ChatListStatus.failure,
          error: e.toString(),
        ));
      }
    } finally {
      _busy = false;
    }
  }

  void _onUpdate(ConversationUpdateEvent e) {
    if (state.status != ChatListStatus.ready) return;
    final index = state.conversations.indexWhere((c) => c.id == e.conversationId);
    if (index == -1) {
      refresh();
      return;
    }
    final current = state.conversations[index];
    final last = e.lastMessage;
    final isActive = e.conversationId == activeConversationId;
    final fromOther = last != null && last.senderId != myId;

    final updated = current.copyWith(
      lastMessage: last,
      updatedAt: last?.createdAt,
      unreadCount: isActive ? 0 : (e.unreadCount ?? (fromOther ? current.unreadCount + 1 : current.unreadCount)),
    );
    final list = [...state.conversations]
      ..removeAt(index)
      ..insert(0, updated);
    emit(ChatListState(status: ChatListStatus.ready, conversations: list));
  }

  void _onMessage(ChatMessage m) {
    if (state.status != ChatListStatus.ready) return;
    final index = state.conversations.indexWhere((c) => c.id == m.conversationId);
    if (index == -1) {
      refresh();
      return;
    }

    final current = state.conversations[index];
    final fromOther = m.senderId != myId;
    final isActive = m.conversationId == activeConversationId;

    final updated = current.copyWith(
      lastMessage: m,
      updatedAt: m.createdAt,
      unreadCount: fromOther && !isActive
          ? current.unreadCount + 1
          : current.unreadCount,
    );

    final list = [...state.conversations]
      ..removeAt(index)
      ..insert(0, updated);
    emit(ChatListState(status: ChatListStatus.ready, conversations: list));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _messageSub?.cancel();
    _updateSub?.cancel();
    _connectionSub?.cancel();
    return super.close();
  }
}