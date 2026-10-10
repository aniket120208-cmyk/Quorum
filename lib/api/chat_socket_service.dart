import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:quorum/token_storage.dart';
import '../models/chat_models.dart';
import 'api_client.dart';
import 'api_configuration.dart';
import 'api_exception.dart';

class TypingEvent {
  const TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
  final String conversationId;
  final String userId;
  final bool isTyping;
}

class ReadEvent {
  const ReadEvent({
    required this.conversationId,
    required this.userId,
    required this.messageId,
    this.lastReadSeq,
  });
  final String conversationId;
  final String userId;
  final String? messageId;
  final int? lastReadSeq;
}

class PresenceEvent {
  const PresenceEvent({
    required this.userId,
    required this.online,
    this.lastSeen,
  });
  final String userId;
  final bool online;
  final DateTime? lastSeen;
}

class ConversationUpdateEvent {
  const ConversationUpdateEvent({
    required this.conversationId,
    this.lastMessage,
    this.unreadCount,
    this.raw = const {},
  });
  final String conversationId;
  final ChatMessage? lastMessage;
  final int? unreadCount;
  final Map<String, dynamic> raw;
}

class ConversationRemovedEvent {
  const ConversationRemovedEvent({
    required this.conversationId,
    this.removedBy,
  });
  final String conversationId;
  final String? removedBy;
}

class ChatSocketService {
  ChatSocketService({
    required ApiClient api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokens = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokens;

  static const _ackTimeout = Duration(seconds: 15);
  static const _maxAuthRetries = 3;

  io.Socket? _socket;
  Future<void>? _connecting;
  int _authRetries = 0;

  final Set<String> _rooms = {};
  final Set<String> _online = {};
  final Map<String, DateTime> _lastSeen = {};
  final _connection = StreamController<bool>.broadcast();
  final _messages = StreamController<ChatMessage>.broadcast();
  final _typing = StreamController<TypingEvent>.broadcast();
  final _reads = StreamController<ReadEvent>.broadcast();
  final _presence = StreamController<PresenceEvent>.broadcast();
  final _updates = StreamController<ConversationUpdateEvent>.broadcast();
  final _removed = StreamController<ConversationRemovedEvent>.broadcast();

  bool get isConnected => _socket?.connected == true;
  Stream<bool> get connection => _connection.stream;
  Stream<ChatMessage> get messageNew => _messages.stream;
  Stream<TypingEvent> get typing => _typing.stream;
  Stream<ReadEvent> get reads => _reads.stream;
  Stream<PresenceEvent> get presence => _presence.stream;
  Stream<ConversationUpdateEvent> get conversationUpdates => _updates.stream;
  Stream<ConversationRemovedEvent> get conversationRemoved => _removed.stream;

  bool isOnline(String userId) => _online.contains(userId);
  DateTime? lastSeen(String userId) => _lastSeen[userId];

  Future<void> connect() {
    if (_socket != null) return Future.value();
    return _connecting ??= _open().whenComplete(() => _connecting = null);
  }

  Future<void> _open() async {
    var token = _tokens.accessToken;
    if (token == null || token.isEmpty) {
      await _api.refreshSession();
      token = _tokens.accessToken;
    }
    if (token == null || token.isEmpty) return;

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      _authRetries = 0;
      for (final id in List<String>.of(_rooms)) {
        _emitJoin(socket, id);
      }
      _connection.add(true);
    });

    socket.onDisconnect((_) {
      _connection.add(false);
    });

    socket.onConnectError((error) {
      _connection.add(false);
      _handleConnectError(socket, error);
    });

    socket.io.on('reconnect_attempt', (_) {
      final latest = _tokens.accessToken;
      if (latest != null && latest.isNotEmpty) {
        socket.auth = {'token': latest};
      }
    });

    socket.on('message:new', (data) {
      final map = _asMap(data);
      if (map != null) _messages.add(ChatMessage.fromJson(map));
    });

    socket.on('conversation:update', (data) {
      final map = _asMap(data);
      if (map == null) return;
      final id = '${map['conversationId'] ?? map['id'] ?? ''}';
      if (id.isEmpty) return;
      final last = _asMap(map['lastMessage']);
      final unread = map['unreadCount'];
      _updates.add(ConversationUpdateEvent(
        conversationId: id,
        lastMessage: last == null
            ? null
            : ChatMessage.fromJson({...last, 'conversationId': id}),
        unreadCount: unread is num ? unread.toInt() : null,
        raw: map,
      ));
    });

    socket.on('conversation:removed', (data) {
      final map = _asMap(data);
      final id = '${map?['conversationId'] ?? ''}';
      if (id.isEmpty) return;
      _rooms.remove(id);
      final by = map?['removedBy'];
      _removed.add(ConversationRemovedEvent(
        conversationId: id,
        removedBy: by != null ? '$by' : null,
      ));
    });

    socket.on('message:read', (data) {
      final map = _asMap(data);
      if (map == null) return;
      final seq = map['lastReadSeq'];
      _reads.add(ReadEvent(
        conversationId: '${map['conversationId'] ?? ''}',
        userId: '${map['userId'] ?? ''}',
        messageId: map['lastReadMessageId'] != null
            ? '${map['lastReadMessageId']}'
            : (map['messageId'] != null ? '${map['messageId']}' : null),
        lastReadSeq: seq is num ? seq.toInt() : null,
      ));
    });

    socket.on('typing:start', (data) => _onTyping(data, true));
    socket.on('typing:stop', (data) => _onTyping(data, false));

    socket.on('presence:online', (data) {
      final map = _asMap(data);
      final userId = map == null ? null : '${map['userId']}';
      if (userId == null) return;
      _online.add(userId);
      _presence.add(PresenceEvent(userId: userId, online: true));
    });

    socket.on('presence:offline', (data) {
      final map = _asMap(data);
      if (map == null) return;
      final userId = '${map['userId']}';
      final seen = DateTime.tryParse('${map['lastSeen']}')?.toLocal();
      _online.remove(userId);
      if (seen != null) _lastSeen[userId] = seen;
      _presence.add(
        PresenceEvent(userId: userId, online: false, lastSeen: seen),
      );
    });

    socket.connect();
  }

  Future<void> _handleConnectError(io.Socket socket, dynamic error) async {
    if (_socket != socket) return;
    final text = '$error'.toLowerCase();
    final looksLikeAuth = const ['auth', 'token', 'jwt', 'unauthor', 'expired']
        .any(text.contains);
    if (!looksLikeAuth || _authRetries >= _maxAuthRetries) return;
    _authRetries++;
    final refreshed = await _api.refreshSession();
    if (!refreshed || _socket != socket) return;
    final token = _tokens.accessToken;
    if (token == null || token.isEmpty) return;
    socket.auth = {'token': token};
    socket.connect();
  }

  void _onTyping(dynamic data, bool isTyping) {
    final map = _asMap(data);
    if (map == null) return;
    _typing.add(TypingEvent(
      conversationId: '${map['conversationId'] ?? ''}',
      userId: '${map['userId'] ?? ''}',
      isTyping: isTyping,
    ));
  }

  Future<bool> _emitJoin(io.Socket socket, String conversationId) {
    final completer = Completer<bool>();
    socket.emitWithAck(
      'conversation:join',
      {'conversationId': conversationId},
      ack: (dynamic response) {
        final res = response is List && response.isNotEmpty
            ? response.first
            : response;
        final ok = _asMap(res)?['success'] == true;
        if (!ok) _rooms.remove(conversationId);
        if (!completer.isCompleted) completer.complete(ok);
      },
    );
    return completer.future.timeout(
      _ackTimeout,
      onTimeout: () => false,
    );
  }

  Future<bool> joinConversation(String conversationId) async {
    _rooms.add(conversationId);
    final socket = _socket;
    if (socket == null || !socket.connected) return false;
    return _emitJoin(socket, conversationId);
  }

  void leaveConversation(String conversationId) {
    _rooms.remove(conversationId);
    if (isConnected) {
      _socket!.emit('conversation:leave', {'conversationId': conversationId});
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String clientMessageId,
    String content = '',
    String? fileUrl,
    String? fileType,
  }) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return Future.error(
        const ApiException("You're offline. Reconnecting…"),
      );
    }

    final completer = Completer<ChatMessage>();
    socket.emitWithAck(
      'message:send',
      {
        'conversationId': conversationId,
        'clientMessageId': clientMessageId,
        if (content.isNotEmpty || fileUrl == null) 'content': content,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileType != null) 'fileType': fileType,
      },
      ack: (dynamic response) {
        if (completer.isCompleted) return;
        final res = response is List && response.isNotEmpty
            ? response.first
            : response;
        final map = _asMap(res);
        final data = _asMap(map?['data']);
        if (map != null && map['success'] == true && data != null) {
          completer.complete(ChatMessage.fromJson({
            ...data,
            'conversationId': data['conversationId'] ?? conversationId,
            'clientMessageId': clientMessageId,
          }));
        } else {
          completer.completeError(ApiException(_ackError(map)));
          if (map?['code'] == 'UNAUTHORIZED') {
            _api.refreshSession().then((ok) {
              final t = _tokens.accessToken;
              if (ok && t != null && t.isNotEmpty) {
                _socket?.auth = {'token': t};
              }
            });
          }
        }
      },
    );

    return completer.future.timeout(
      _ackTimeout,
      onTimeout: () => throw const ApiException('Message timed out.'),
    );
  }

  String _ackError(Map<String, dynamic>? map) {
    switch (map?['code']) {
      case 'UNAUTHORIZED':
        return 'Session expired. Reconnecting…';
      case 'NOT_PARTICIPANT':
        return "You're not a member of this conversation.";
      case 'RATE_LIMITED':
        return "You're sending too fast. Wait a moment and try again.";
      case 'INVALID_PAYLOAD':
        return 'That message could not be sent.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again.';
    }
    final reason = map?['message'] ?? map?['error'];
    return reason is String ? reason : 'Could not send message.';
  }

  bool markRead(String conversationId, String messageId) {
    if (!isConnected) return false;
    _socket!.emit('message:read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
    return true;
  }

  void sendTyping(String conversationId, {required bool typing}) {
    if (!isConnected) return;
    _socket!.emit(typing ? 'typing:start' : 'typing:stop', {
      'conversationId': conversationId,
    });
  }

  void disconnect() {
    final socket = _socket;
    _socket = null;
    _rooms.clear();
    _online.clear();
    _lastSeen.clear();
    _authRetries = 0;
    if (socket != null) {
      socket.dispose();
      _connection.add(false);
    }
  }

  void dispose() {
    disconnect();
    _connection.close();
    _messages.close();
    _typing.close();
    _reads.close();
    _presence.close();
    _updates.close();
    _removed.close();
  }

  Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}