import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:quorum/token_storage.dart';
import 'api_client.dart';
import 'api_configuration.dart';
import 'api_exception.dart';

enum MeetingPhase {
  idle,
  connecting,
  waitingRoom,
  inCall,
  rejected,
  ended,
  failed,
}

class RemotePeer {
  RemotePeer(this.userId, this.name);
  final String userId;
  String name;
  bool isMuted = false;
  bool isVideoOff = false;
  bool hasVideo = false;
  bool fitContain = false;
  MediaStream? audioStream;
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  late final Future<void> ready = renderer.initialize();
}

class WaitingGuest {
  const WaitingGuest(this.userId, this.name);
  final String userId;
  final String name;
}

class MeetingChatMessage {
  const MeetingChatMessage({
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });
  final String senderId;
  final String senderName;
  final String content;
  final String timestamp;
}

class MeetingService extends ChangeNotifier {
  MeetingService({
    required this.api,
    required this.tokens,
    required this.meetingCode,
    required this.userId,
    required this.userName,
  });

  final ApiClient api;
  final TokenStorage tokens;
  final String meetingCode;
  final String userId;
  final String userName;

  bool isHost = false;
  Future<void>? _mediaInit;

  static const _ackTimeout = Duration(seconds: 15);
  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  MeetingPhase phase = MeetingPhase.idle;
  String? message;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  bool _localRendererReady = false;
  MediaStream? _localStream;
  bool isMuted = false;
  bool isVideoOff = false;
  bool isFrontCamera = true;
  bool speakerOn = true;

  bool get hasLocalVideo =>
      (_localStream?.getVideoTracks().isNotEmpty ?? false);
  bool get hasLocalAudio =>
      (_localStream?.getAudioTracks().isNotEmpty ?? false);

  final Map<String, RemotePeer> _peers = {};
  List<RemotePeer> participants = [];
  final List<WaitingGuest> waitingList = [];
  final List<MeetingChatMessage> chat = [];
  bool chatOpen = false;
  int unreadChat = 0;
  final Map<String, int> _selfEchoes = {};

  bool isScreenSharing = false;
  MediaStream? _screenStream;
  MediaStreamTrack? _cameraTrack;

  io.Socket? _socket;
  RTCPeerConnection? _publisher;
  bool _publisherRemoteSet = false;
  final List<RTCIceCandidate> _pendingPublisherCandidates = [];
  final Map<String, RTCPeerConnection> _consumers = {};
  final Map<String, bool> _consumerRemoteSet = {};
  final Map<String, List<RTCIceCandidate>> _pendingConsumerCandidates = {};
  final Set<String> _subscribed = {};
  bool _mediaStarted = false;
  bool _disposed = false;

  Future<void> initLocalMedia({bool video = true}) {
    return _mediaInit ??= _initLocalMedia(video: video);
  }

  Future<void> _initLocalMedia({bool video = true}) async {
    if (!_localRendererReady) {
      await localRenderer.initialize();
      _localRendererReady = true;
    }
    if (_localStream != null) return;

    Future<MediaStream> capture(bool withVideo) {
      return navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': withVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 960},
                'height': {'ideal': 540},
                'frameRate': {'ideal': 24},
              }
            : false,
      });
    }

    try {
      _localStream = await capture(video);
    } catch (_) {
      try {
        _localStream = await capture(false);
      } catch (_) {
        _localStream = null;
      }
    }

    localRenderer.srcObject = _localStream;
    if (!hasLocalVideo) isVideoOff = true;
    if (!hasLocalAudio) isMuted = true;
    _notify();
  }


  void _log(String m) {
    if (kDebugMode) debugPrint('[MEETING][$userName] $m');
  }

  String _tokenOwner(String? token) {
    try {
      if (token == null || token.isEmpty) return 'NO TOKEN';
      final parts = token.split('.');
      if (parts.length != 3) return 'not a JWT';
      final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])));
      return payload;
    } catch (e) {
      return 'decode failed: $e';
    }
  }


  Future<void> join() async {
    if (phase == MeetingPhase.connecting ||
        phase == MeetingPhase.inCall ||
        phase == MeetingPhase.waitingRoom) {
      return;
    }
    _setPhase(MeetingPhase.connecting);

    if (_mediaInit != null) {
      try {
        await _mediaInit;
      } catch (_) {}
    }

    var token = tokens.accessToken;
    if (token == null || token.isEmpty) {
      await api.refreshSession();
      token = tokens.accessToken;
    }

    _log('JOIN start | meetingCode="$meetingCode" | userId="$userId" | '
        'isHost(client)=$isHost | role sent=${isHost ? 'host' : 'participant'}');
    _log('JWT payload: ${_tokenOwner(token)}');

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
            'userId': userId,
            'name': userName,
            'role': isHost ? 'host' : 'participant',
            if (token != null) 'token': token,
          })
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;
    _registerListeners(socket);
    if (kDebugMode) {
      socket.onAny((event, data) => _log('<= $event  $data'));
    }

    final connected = Completer<void>();
    socket.onConnect((_) {
      if (!connected.isCompleted) connected.complete();
    });
    socket.onConnectError((e) {
      if (!connected.isCompleted) {
        connected.completeError(
          const ApiException("Couldn't connect to the meeting server."),
        );
      }
    });
    socket.connect();

    try {
      await connected.future.timeout(_ackTimeout);
      _log('=> meeting:join {meetingCode: $meetingCode}');
      final ack = await _emitAck('meeting:join', {'meetingCode': meetingCode});
      _log('meeting:join ACK = $ack');
      if (ack['success'] != true) {
        throw ApiException('${ack['message'] ?? 'Could not join the meeting.'}');
      }
      final data = _asMap(ack['data']);
      if (data?['status'] == 'waiting_room') {
        _setPhase(MeetingPhase.waitingRoom);
      } else {
        _readParticipants(data?['participants']);
        _readWaitingRoom(data?['waitingRoom']);
        await _enterCall();
      }
    } catch (e) {
      message = e is ApiException ? e.message : 'Could not join the meeting.';
      await _teardown();
      _setPhase(MeetingPhase.failed);
    }
  }

  Future<void> _enterCall() async {
    if (phase == MeetingPhase.inCall) return;
    _setPhase(MeetingPhase.inCall);
    try {
      await Helper.setSpeakerphoneOn(true);
      speakerOn = true;
    } catch (_) {}
    if (isMuted) {
      _socket?.emit('meeting:toggle-mic',
          {'meetingCode': meetingCode, 'isMuted': true});
    }
    if (isVideoOff) {
      _socket?.emit('meeting:toggle-cam',
          {'meetingCode': meetingCode, 'isVideoOff': true});
    }
    await _startPublishing();
  }


  void _registerListeners(io.Socket s) {
    s.on('meeting:joined', (d) {
      _readParticipants(_asMap(d)?['participants']);
    });

    s.on('meeting:guest-waiting', (d) {
      final u = _asMap(_asMap(d)?['user']);
      if (u == null) return;
      final id = '${u['userId'] ?? u['id']}';
      waitingList.removeWhere((g) => g.userId == id);
      waitingList.add(WaitingGuest(id, '${u['name'] ?? 'Guest'}'));
      _notify();
    });

    s.on('meeting:admitted', (_) async {
      if (phase != MeetingPhase.waitingRoom) return;
      await _enterCall();
    });

    s.on('meeting:rejected', (d) {
      message = '${_asMap(d)?['message'] ?? 'The host declined your request.'}';
      _teardown();
      _setPhase(MeetingPhase.rejected);
    });

    s.on('meeting:presence-update', (d) async {
      final list = _asMap(d)?['participants'];
      _readParticipants(list);
      if (phase == MeetingPhase.waitingRoom && list is List) {
        final me = list.any((p) => _asMap(p)?['userId'] == userId);
        if (me) await _enterCall();
      }
    });

    s.on('meeting:participant-joined', (d) {
      _readParticipants(_asMap(d)?['participants']);
    });

    s.on('meeting:participant-left', (d) {
      final map = _asMap(d);
      final left = '${map?['userId']}';
      _readParticipants(map?['participants']);
      if (!participants.any((p) => p.userId == left)) _removePeer(left);
    });

    s.on('meeting:participant-mic-status', (d) {
      final m = _asMap(d);
      final p = _peers['${m?['userId']}'];
      if (p == null) return;
      p.isMuted = m?['isMuted'] == true;
      _notify();
    });

    s.on('meeting:participant-cam-status', (d) {
      final m = _asMap(d);
      final p = _peers['${m?['userId']}'];
      if (p == null) return;
      p.isVideoOff = m?['isVideoOff'] == true;
      _notify();
    });

    s.on('meeting:muted-by-host', (d) {
      _localStream?.getAudioTracks().forEach((t) => t.enabled = false);
      isMuted = true;
      message = '${_asMap(d)?['message'] ?? 'You have been muted by the host'}';
      _notify();
    });

    s.on('meeting:new-message', (d) {
      final m = _asMap(d);
      if (m == null) return;
      final senderId = '${m['senderId']}';
      final content = '${m['content'] ?? ''}';
      if (senderId == userId) {
        _selfEchoes[content] = (_selfEchoes[content] ?? 0) + 1;
      } else if (!chatOpen) {
        unreadChat++;
      }
      chat.add(MeetingChatMessage(
        senderId: senderId,
        senderName: '${m['senderName'] ?? ''}',
        content: content,
        timestamp: '${m['timestamp'] ?? DateTime.now().toIso8601String()}',
      ));
      _notify();
    });

    s.on('meeting:ended', (d) async {
      message = '${_asMap(d)?['message'] ?? 'The meeting has ended.'}';
      await _teardown();
      _setPhase(MeetingPhase.ended);
    });

    s.on('sfu:answer', (d) async {
      final sdp = _asMap(_asMap(d)?['sdp']);
      final pc = _publisher;
      if (sdp == null || pc == null) return;
      await pc.setRemoteDescription(
        RTCSessionDescription('${sdp['sdp']}', '${sdp['type']}'),
      );
      _publisherRemoteSet = true;
      for (final c in _pendingPublisherCandidates) {
        await pc.addCandidate(c);
      }
      _pendingPublisherCandidates.clear();
    });

    s.on('sfu:ice-candidate', (d) async {
      final map = _asMap(d);
      final c = _asMap(map?['candidate']);
      if (c == null || c['candidate'] == null) return;
      final cand = RTCIceCandidate(
        '${c['candidate']}',
        c['sdpMid'] as String?,
        (c['sdpMLineIndex'] as num?)?.toInt(),
      );
      final trackId = map?['trackId'];
      if (trackId != null && _consumers.containsKey('$trackId')) {
        final key = '$trackId';
        if (_consumerRemoteSet[key] == true) {
          await _consumers[key]!.addCandidate(cand);
        } else {
          (_pendingConsumerCandidates[key] ??= []).add(cand);
        }
        return;
      }
      final pc = _publisher;
      if (pc == null) return;
      if (_publisherRemoteSet) {
        await pc.addCandidate(cand);
      } else {
        _pendingPublisherCandidates.add(cand);
      }
    });

    s.on('sfu:joined', (d) {
      final tracks = _asMap(d)?['existingTracks'];
      if (tracks is! List) return;
      for (final t in tracks) {
        final m = _asMap(t);
        if (m != null) _subscribeFromMap(m);
      }
    });

    s.on('sfu:new-producer', (d) {
      final m = _asMap(d);
      if (m != null) _subscribeFromMap(m);
    });

    s.on('sfu:subscribed', (d) async {
      final m = _asMap(d);
      final pc = _consumers['${m?['trackId']}'];
      final sdp = _asMap(m?['sdp']);
      if (pc == null || sdp == null) return;
      await pc.setRemoteDescription(
        RTCSessionDescription('${sdp['sdp']}', '${sdp['type']}'),
      );
      final key = '${m?['trackId']}';
      _consumerRemoteSet[key] = true;
      final pending = _pendingConsumerCandidates.remove(key) ?? [];
      for (final c in pending) {
        await pc.addCandidate(c);
      }
    });

    s.on('sfu:error', (d) {
      message = '${_asMap(d)?['message'] ?? 'Media server error'}';
      _notify();
    });
  }


  Future<void> _startPublishing() async {
    if (_mediaStarted) return;
    _mediaStarted = true;
    final socket = _socket;
    if (socket == null) return;

    final pc = await createPeerConnection(_rtcConfig);
    _publisher = pc;

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
    } else {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      socket.emit('sfu:ice-candidate', {
        'roomCode': meetingCode,
        'peerId': userId,
        'candidate': c.toMap(),
      });
    };

    socket.emit('sfu:join', {
      'roomCode': meetingCode,
      'peerId': userId,
      'name': userName,
    });

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    socket.emit('sfu:offer', {
      'roomCode': meetingCode,
      'peerId': userId,
      'sdp': {'type': offer.type, 'sdp': offer.sdp},
    });
  }


  void _subscribeFromMap(Map<String, dynamic> m) {
    final peerId = '${m['peerId']}';
    if (peerId == userId) return;
    final trackId = '${m['trackId']}';
    final kind = '${m['kind']}';
    if (!_subscribed.add(trackId)) return;
    _subscribeToTrack(trackId, kind, peerId);
  }

  Future<void> _subscribeToTrack(
    String trackId,
    String kind,
    String peerId,
  ) async {
    final socket = _socket;
    if (socket == null) return;

    final pc = await createPeerConnection(_rtcConfig);
    _consumers[trackId] = pc;
    _consumerRemoteSet[trackId] = false;

    await pc.addTransceiver(
      kind: kind == 'audio'
          ? RTCRtpMediaType.RTCRtpMediaTypeAudio
          : RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    pc.onTrack = (RTCTrackEvent e) async {
      final peer = _peerFor(peerId);
      MediaStream? stream = e.streams.isNotEmpty ? e.streams.first : null;
      if (stream == null) {
        stream = await createLocalMediaStream('remote_${peerId}_${e.track.id}');
        await stream.addTrack(e.track);
      }
      if (e.track.kind != 'video') {
        e.track.enabled = true;
        peer.audioStream = stream;
        _notify();
        return;
      }
      await peer.ready;
      peer.renderer.srcObject = stream;
      peer.hasVideo = true;
      _notify();
    };

    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      socket.emit('sfu:ice-candidate', {
        'roomCode': meetingCode,
        'peerId': userId,
        'trackId': trackId,
        'candidate': c.toMap(),
      });
    };

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    socket.emit('sfu:subscribe', {
      'roomCode': meetingCode,
      'subscriberPeerId': userId,
      'trackId': trackId,
      'sdp': {'type': offer.type, 'sdp': offer.sdp},
    });
  }


  void toggleMic() {
    if (!hasLocalAudio) return;
    isMuted = !isMuted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !isMuted);
    _socket?.emit('meeting:toggle-mic',
        {'meetingCode': meetingCode, 'isMuted': isMuted});
    _notify();
  }

  void toggleCamera() {
    if (!hasLocalVideo || isScreenSharing) return;
    isVideoOff = !isVideoOff;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !isVideoOff);
    _socket?.emit('meeting:toggle-cam',
        {'meetingCode': meetingCode, 'isVideoOff': isVideoOff});
    _notify();
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty || isScreenSharing) return;
    await Helper.switchCamera(tracks.first);
    isFrontCamera = !isFrontCamera;
    _notify();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    try {
      await Helper.setSpeakerphoneOn(speakerOn);
    } catch (_) {}
    _notify();
  }

  void admit(String id) => _hostAction('meeting:admit-participant', id);
  void reject(String id) => _hostAction('meeting:reject-participant', id);

  void _hostAction(String event, String id) {
    final payload = {
      'meetingCode': meetingCode,
      'userId': id,
      'targetUserId': id,
    };
    _log('=> $event $payload');
    _socket?.emitWithAck(event, payload, ack: (dynamic r) {
      final res = _asMap(r is List && r.isNotEmpty ? r.first : r);
      _log('$event ACK = $res');
      if (res == null || res['success'] != true) {
        message = '${res?['message'] ?? 'Action failed (no response from server).'}';
        _notify();
      }
    });
    waitingList.removeWhere((g) => g.userId == id);
    _notify();
  }

  void muteParticipant(String id) {
    _socket?.emitWithAck('meeting:mute-participant',
        {'meetingCode': meetingCode, 'targetUserId': id}, ack: (_) {});
  }

  Future<String?> sendMessage(String text) async {
    final content = text.trim();
    if (content.isEmpty) return null;
    final ack = await _emitAck(
        'meeting:send-message', {'meetingCode': meetingCode, 'content': content});
    if (ack['success'] != true) return '${ack['message'] ?? 'Message not sent'}';

    await Future.delayed(const Duration(milliseconds: 700));
    final echoed = _selfEchoes[content] ?? 0;
    if (echoed > 0) {
      _selfEchoes[content] = echoed - 1;
    } else {
      chat.add(MeetingChatMessage(
        senderId: userId,
        senderName: userName,
        content: content,
        timestamp: DateTime.now().toIso8601String(),
      ));
      _notify();
    }
    return null;
  }

  void setChatOpen(bool open) {
    chatOpen = open;
    if (open) unreadChat = 0;
    _notify();
  }

  Future<String?> startScreenShare() async {
    if (isScreenSharing) return null;
    final pc = _publisher;
    if (pc == null || phase != MeetingPhase.inCall) {
      return 'Join the call before sharing your screen.';
    }

    RTCRtpSender? videoSender;
    for (final sender in await pc.getSenders()) {
      if (sender.track?.kind == 'video') videoSender = sender;
    }
    if (videoSender == null) {
      return 'Screen share needs camera access to be granted (video connection missing).';
    }

    try {
      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
      final screenTrack = stream.getVideoTracks().first;
      _cameraTrack = videoSender.track;
      await videoSender.replaceTrack(screenTrack);

      _screenStream = stream;
      screenTrack.onEnded = () => stopScreenShare();
      isScreenSharing = true;
      localRenderer.srcObject = stream;

      if (isVideoOff) {
        _socket?.emit('meeting:toggle-cam',
            {'meetingCode': meetingCode, 'isVideoOff': false});
      }
      _notify();
      return null;
    } catch (_) {
      return 'Screen sharing was cancelled or is not available.';
    }
  }

  Future<void> stopScreenShare() async {
    if (!isScreenSharing) return;
    isScreenSharing = false;

    final pc = _publisher;
    if (pc != null && _cameraTrack != null) {
      for (final sender in await pc.getSenders()) {
        if (sender.track?.kind == 'video') {
          await sender.replaceTrack(_cameraTrack);
        }
      }
    }
    _cameraTrack = null;

    _screenStream?.getTracks().forEach((t) => t.stop());
    await _screenStream?.dispose();
    _screenStream = null;
    localRenderer.srcObject = _localStream;

    if (isVideoOff) {
      _socket?.emit('meeting:toggle-cam',
          {'meetingCode': meetingCode, 'isVideoOff': true});
    }
    _notify();
  }

  Future<void> leave({bool endForAll = false}) async {
    await stopScreenShare();
    final socket = _socket;
    if (socket != null && socket.connected) {
      if (endForAll && isHost) {
        socket.emit('meeting:end', {'meetingCode': meetingCode});
      } else {
        socket.emit('meeting:leave', {'meetingCode': meetingCode});
      }
    }
    await _teardown();
  }


  void _readParticipants(dynamic raw) {
    if (raw is! List) return;
    final seen = <String>{};
    final list = <RemotePeer>[];
    for (final item in raw) {
      final m = _asMap(item);
      if (m == null) continue;
      final id = '${m['userId'] ?? m['id']}';
      if (id == userId || !seen.add(id)) continue;
      final peer = _peerFor(id, name: '${m['name'] ?? m['userName'] ?? 'Guest'}');
      if (m['isMuted'] is bool) peer.isMuted = m['isMuted'] as bool;
      if (m['isVideoOff'] is bool) peer.isVideoOff = m['isVideoOff'] as bool;
      list.add(peer);
    }
    participants = list;
    _notify();
  }

  void _readWaitingRoom(dynamic raw) {
    if (!isHost || raw is! List) return;
    for (final item in raw) {
      final m = _asMap(item);
      if (m == null) continue;
      final u = _asMap(m['user']) ?? m;
      final id = '${u['userId'] ?? u['id']}';
      if (id.isEmpty || id == 'null' || id == userId) continue;
      waitingList.removeWhere((g) => g.userId == id);
      waitingList.add(WaitingGuest(id, '${u['name'] ?? 'Guest'}'));
    }
    _notify();
  }

  RemotePeer _peerFor(String id, {String? name}) {
    final peer = _peers.putIfAbsent(id, () => RemotePeer(id, name ?? 'Guest'));
    if (name != null && name.isNotEmpty) peer.name = name;
    return peer;
  }

  void _removePeer(String id) {
    final peer = _peers.remove(id);
    if (peer != null) {
      peer.renderer.srcObject = null;
      peer.renderer.dispose();
    }
    participants = participants.where((p) => p.userId != id).toList();
    _notify();
  }

  Future<Map<String, dynamic>> _emitAck(
    String event,
    Map<String, dynamic> payload,
  ) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return Future.value({'success': false, 'message': 'You are offline.'});
    }
    final c = Completer<Map<String, dynamic>>();
    socket.emitWithAck(event, payload, ack: (dynamic r) {
      final res = r is List && r.isNotEmpty ? r.first : r;
      if (!c.isCompleted) c.complete(_asMap(res) ?? {'success': false});
    });
    return c.future.timeout(
      _ackTimeout,
      onTimeout: () => {'success': false, 'message': 'Request timed out.'},
    );
  }

  Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  void _setPhase(MeetingPhase p) {
    phase = p;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _teardown() async {
    if (isScreenSharing) {
      isScreenSharing = false;
      _screenStream?.getTracks().forEach((t) => t.stop());
      _screenStream = null;
      localRenderer.srcObject = _localStream;
    }
    _mediaStarted = false;
    _publisherRemoteSet = false;
    _pendingPublisherCandidates.clear();
    final pub = _publisher;
    _publisher = null;
    await pub?.close();
    for (final pc in _consumers.values) {
      await pc.close();
    }
    _consumers.clear();
    _consumerRemoteSet.clear();
    _pendingConsumerCandidates.clear();
    _subscribed.clear();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _teardown();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    localRenderer.srcObject = null;
    localRenderer.dispose();
    for (final p in _peers.values) {
      p.renderer.srcObject = null;
      p.renderer.dispose();
    }
    _peers.clear();
    super.dispose();
  }
}