class ChatUser {
  const ChatUser({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.avatar,
    this.lastReadMessageId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final String? lastReadMessageId;

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    final nested = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;
    final avatar = nested['avatar'];
    final lastRead = json['lastReadMessageId'] ?? nested['lastReadMessageId'];
    return ChatUser(
      id: '${nested['id'] ?? nested['_id'] ?? json['userId'] ?? ''}',
      name: '${nested['name'] ?? ''}',
      email: '${nested['email'] ?? ''}',
      phone: '${nested['phone'] ?? ''}',
      avatar: avatar is String && avatar.isNotEmpty ? avatar : null,
      lastReadMessageId: lastRead != null ? '$lastRead' : null,
    );
  }
}

enum MessageStatus { sending, sent, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.clientId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.fileUrl,
    this.fileType,
    this.status = MessageStatus.sent,
  });

  final String? id;
  final String? clientId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String? fileUrl;
  final String? fileType;
  final DateTime createdAt;
  final MessageStatus status;

  bool get hasMedia => fileUrl != null && fileUrl!.isNotEmpty;

  String get previewText {
    if (text.trim().isNotEmpty) return text;
    switch (fileType) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'file':
        return 'File';
    }
    return '';
  }

  ChatMessage copyWith({
    MessageStatus? status,
    String? fileUrl,
    String? fileType,
  }) {
    return ChatMessage(
      id: id,
      clientId: clientId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: createdAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      status: status ?? this.status,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap =
        sender is Map ? Map<String, dynamic>.from(sender) : const {};
    final fileUrl = json['fileUrl'];
    final fileType = json['fileType'];
    final clientId = json['clientMessageId'] ?? json['clientId'];
    return ChatMessage(
      id: json['id'] != null || json['_id'] != null
          ? '${json['id'] ?? json['_id']}'
          : null,
      clientId: clientId != null ? '$clientId' : null,
      conversationId: '${json['conversationId'] ?? ''}',
      senderId: '${senderMap['id'] ?? senderMap['_id'] ?? json['senderId'] ?? ''}',
      senderName: '${senderMap['name'] ?? json['senderName'] ?? ''}',
      text: '${json['content'] ?? json['text'] ?? ''}',
      fileUrl: fileUrl is String && fileUrl.isNotEmpty ? fileUrl : null,
      fileType: fileType is String && fileType.isNotEmpty ? fileType : null,
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
    );
  }
}

class MessagePage {
  const MessagePage({
    required this.messages,
    this.nextCursor,
    this.hasNextPage = false,
  });

  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool hasNextPage;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.members,
    required this.createdBy,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final bool isGroup;
  final String name;
  final List<ChatUser> members;
  final String createdBy;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  ChatUser? otherMember(String myId) {
    for (final m in members) {
      if (m.id != myId) return m;
    }
    return null;
  }

  String titleFor(String myId) {
    if (isGroup) return name.isEmpty ? 'Group' : name;
    final other = otherMember(myId);
    return other?.name.isNotEmpty == true ? other!.name : 'Chat';
  }

  Conversation copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      isGroup: isGroup,
      name: name,
      members: members,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? json['_id']}';
    final rawMembers = json['participants'] ?? json['members'];
    final last = json['lastMessage'];
    final lastMessage = last is Map
        ? ChatMessage.fromJson({
            ...Map<String, dynamic>.from(last),
            'conversationId': id,
          })
        : null;
    return Conversation(
      id: id,
      isGroup: json['isGroup'] == true || json['type'] == 'group',
      name: '${json['name'] ?? ''}',
      createdBy: '${json['createdBy'] ?? ''}',
      members: rawMembers is List
          ? rawMembers
              .whereType<Map>()
              .map((e) => ChatUser.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      lastMessage: lastMessage,
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
      updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toLocal() ??
          lastMessage?.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}