import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/chat_models.dart';

class ChatRepository {
  ChatRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;
  static const _prefixes = ['/api', '/api/chat', '/api/v1', '/api/v1/chat'];
  String _prefix = _prefixes.first;

  Future<ApiResponse> _chat(
    String method,
    String route, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final order = [_prefix, ..._prefixes.where((p) => p != _prefix)];
    final tried = <String>[];
    for (final prefix in order) {
      final path = '$prefix$route';
      tried.add(path);
      try {
        final res = method == 'POST'
            ? await _api.post(path, body: body, auth: true)
            : await _api.get(path, query: query, auth: true);
        _prefix = prefix;
        return res;
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
    }
    throw ApiException(
      'Chat API not found on the server. Tried: ${tried.join(', ')}',
      statusCode: 404,
    );
  }

  Future<T> _groupCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        throw const ApiException(
          'Group chats are not available yet.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  Conversation _conversationFrom(ApiResponse res) {
    final data = res.data;
    if (data == null) {
      throw const ApiException('Unexpected response from the server.');
    }
    final nested = data['conversation'];
    return Conversation.fromJson(
      nested is Map ? Map<String, dynamic>.from(nested) : data,
    );
  }

  Future<List<Conversation>> fetchConversations() async {
    final res = await _chat('GET', '/conversations');

    final list = _listFromResponse(res, 'conversations')
        .map(Conversation.fromJson)
        .toList();

    list.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    return list;
  }

  Future<Conversation> openDirect(String userId) async {
    final res = await _chat('POST', '/dm', body: {'targetUserId': userId});
    return _conversationFrom(res);
  }

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    return _groupCall(() async {
      final res = await _api.post(
        '/api/chat/conversations/group',
        body: {'name': name.trim(), 'memberIds': memberIds},
        auth: true,
      );
      return _conversationFrom(res);
    });
  }

  Future<Conversation> fetchConversation(String id) async {
    final all = await fetchConversations();
    for (final c in all) {
      if (c.id == id) return c;
    }
    throw const ApiException(
      'Requested resource was not found.',
      statusCode: 404,
    );
  }

  Future<MessagePage> fetchMessages(
    String conversationId, {
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _chat(
      'GET',
      '/conversations/$conversationId/messages',
      query: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return _messagePage(res, conversationId);
  }

  Future<MessagePage> searchMessages(
    String conversationId,
    String query, {
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _chat(
      'GET',
      '/conversations/$conversationId/search',
      query: {
        'q': query.trim(),
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return _messagePage(res, conversationId);
  }

  Future<String> uploadMedia(String filePath, {String folder = 'chat'}) async {
    final sign = await _api.post(
      '/api/uploads/sign',
      body: {'folder': folder},
      auth: true,
    );
    final cfg = sign.data;
    final uploadUrl = cfg?['uploadUrl'];
    if (cfg == null || uploadUrl is! String) {
      throw const ApiException('Could not prepare the upload.');
    }

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'api_key': '${cfg['apiKey']}',
        'timestamp': '${cfg['timestamp']}',
        'signature': '${cfg['signature']}',
        'folder': '${cfg['folder']}',
      });
      final res = await Dio().post<dynamic>(uploadUrl, data: form);
      final body = res.data;
      final url = body is Map ? body['secure_url'] : null;
      if (url is String && url.isNotEmpty) return url;
    } on DioException {
      throw const ApiException('Upload failed. Please try again.');
    }
    throw const ApiException('Upload failed. Please try again.');
  }

  Future<void> registerDevice(String token) async {
    await _api.post(
      '/api/devices',
      body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
      auth: true,
    );
  }

  Future<void> removeDevice(String token) async {
    await _api.delete(
      '/api/devices',
      body: {'token': token},
      auth: true,
    );
  }

  MessagePage _messagePage(ApiResponse res, String conversationId) {
    final data = res.data;
    final messages = _listFromResponse(res, 'messages')
        .map(
          (m) => ChatMessage.fromJson({
            ...m,
            'conversationId': m['conversationId'] ?? conversationId,
          }),
        )
        .toList();
    final cursor = data?['nextCursor'];
    return MessagePage(
      messages: messages,
      nextCursor: cursor != null ? '$cursor' : null,
      hasNextPage: data?['hasNextPage'] == true && cursor != null,
    );
  }

  List<Map<String, dynamic>> _listFromResponse(ApiResponse res, String key) {
    final raw = res.rawData;
    final list = raw is List ? raw : (raw is Map ? raw[key] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<ChatUser>> searchUsers(String query) async {
    Future<ApiResponse> call(String path) =>
        _api.get(path, query: {'q': query.trim()}, auth: true);

    ApiResponse? res;
    ApiException? first;
    for (final path in const [
      '/api/users/search',
      '/api/user/search',
      '/api/chat/users/search',
    ]) {
      try {
        res = await call(path);
        break;
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
        first ??= e;
      }
    }
    if (res == null) throw first!;
    return _listFromResponse(res, 'users').map(ChatUser.fromJson).toList();
  }

  Future<Conversation> renameGroup(String id, String name) {
    return _groupCall(() async {
      final res = await _api.patch(
        '/api/chat/conversations/$id',
        body: {'name': name.trim()},
        auth: true,
      );
      return _conversationFrom(res);
    });
  }

  Future<Conversation> addMembers(String id, List<String> userIds) {
    return _groupCall(() async {
      final res = await _api.post(
        '/api/chat/conversations/$id/members',
        body: {'userIds': userIds},
        auth: true,
      );
      return _conversationFrom(res);
    });
  }

  Future<void> removeMember(String id, String userId) {
    return _groupCall(() async {
      await _api.delete(
        '/api/chat/conversations/$id/members/$userId',
        auth: true,
      );
    });
  }

  Future<void> leaveGroup(String id) {
    return _groupCall(() async {
      await _api.delete(
        '/api/chat/conversations/$id/members/me',
        auth: true,
      );
    });
  }

  bool _contactMatchUnavailable = false;

  Future<List<ChatUser>?> matchPhoneContacts() async {
    if (_contactMatchUnavailable) return <ChatUser>[];
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (status != PermissionStatus.granted) {
      return null;
    }

    final contacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.phone,
        ContactProperty.email,
      },
    );

    final emails = <String>{};
    final phones = <String>{};

    for (final contact in contacts) {
      for (final email in contact.emails) {
        final value = email.address.trim().toLowerCase();
        if (value.isNotEmpty) {
          emails.add(value);
        }
      }

      for (final phone in contact.phones) {
        final value = _normalizePhone(phone.number);

        if (value.length >= 7) {
          phones.add(value);
        }
      }
    }

    if (emails.isEmpty && phones.isEmpty) {
      return <ChatUser>[];
    }

    try {
      final res = await _api.post(
        '/api/chat/contacts/match',
        body: {
          'emails': emails.toList(),
          'phones': phones.toList(),
        },
        auth: true,
      );
      return _listFromResponse(res, 'users').map(ChatUser.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        _contactMatchUnavailable = true;
        return <ChatUser>[];
      }
      rethrow;
    }
  }

  String _normalizePhone(String raw) {
    final trimmed = raw.trim();

    final digits = trimmed.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return trimmed.startsWith('+')
        ? '+$digits'
        : digits;
  }
}