import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quorum/main.dart';
import 'package:share_plus/share_plus.dart';
import 'models/meeting_result.dart';
import 'widgets/call_action_button.dart';
import 'widgets/draggable_pip_view.dart';

enum _Phase { lobby, joining, inCall, leaving }

class _Reaction {
  final int id;
  final String emoji;
  final double x; 
  const _Reaction(this.id, this.emoji, this.x);
}

class _Participant {
  final String name;
  final bool muted;
  const _Participant(this.name, {this.muted = false});
}

class MeetingRoomScreen extends StatefulWidget {
  final String meetingCode;
  final String title;
  const MeetingRoomScreen({super.key, required this.meetingCode, this.title = 'Meeting'});
  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraBusy = false;
  bool _permissionDenied = false;
  bool _cameraFailed = false;

  _Phase _phase = _Phase.lobby;
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _handRaised = false;
  bool _controlsVisible = true;
  bool _dialogOpen = false;

  final List<_Participant> _remote = [];

  DateTime? _joinedAt;
  final ValueNotifier<int> _seconds = ValueNotifier<int>(0);
  Timer? _callTimer;
  Timer? _joinTimer;
  Timer? _hideTimer;

  final List<_Reaction> _reactions = [];
  int _reactionCounter = 0;
  final _random = Random();

  String get _link => 'https://quorum.app/meet/${widget.meetingCode}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _joinTimer?.cancel();
    _hideTimer?.cancel();
    _seconds.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phase == _Phase.leaving) return;
    if (state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_camera == null && !_cameraOff && !_permissionDenied && _cameras.isNotEmpty) {
        _startCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    final camStatus = await Permission.camera.request();
    await Permission.microphone.request();
    if (!mounted) return;
    if (!camStatus.isGranted) {
      setState(() {
        _permissionDenied = true;
        _cameraOff = true;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
    } catch (_) {
      _cameras = [];
    }
    if (!mounted) return;

    if (_cameras.isEmpty) {
      setState(() {
        _cameraFailed = true;
        _cameraOff = true;
      });
      return;
    }

    final front = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    _cameraIndex = front == -1 ? 0 : front;
    await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_cameraBusy || _cameras.isEmpty) return;
    _cameraBusy = true;

    final old = _camera;
    if (mounted) setState(() => _camera = null);
    try {
      await old?.dispose();
    } catch (_) {}

    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted || _cameraOff || _phase == _Phase.leaving) {
        await controller.dispose();
      } else {
        setState(() => _camera = controller);
      }
    } catch (_) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (mounted) setState(() => _cameraFailed = true);
    } finally {
      _cameraBusy = false;
    }
  }

  Future<void> _stopCamera() async {
    final c = _camera;
    if (c == null) return;
    if (mounted) {
      setState(() => _camera = null);
    } else {
      _camera = null;
    }
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    if (_cameraBusy) return;
    if (_permissionDenied) {
      _snack(
        'Camera permission is turned off',
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      );
      return;
    }
    if (_cameras.isEmpty) {
      _snack('No camera available on this device');
      return;
    }

    HapticFeedback.selectionClick();
    if (_cameraOff) {
      setState(() {
        _cameraOff = false;
        _cameraFailed = false;
      });
      await _startCamera();
    } else {
      setState(() => _cameraOff = true);
      await _stopCamera(); 
    }
    _showControls();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _cameraBusy || _cameraOff) return;
    final current = _cameras[_cameraIndex].lensDirection;
    final target = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final idx = _cameras.indexWhere((c) => c.lensDirection == target);
    if (idx == -1) return;

    HapticFeedback.selectionClick();
    _cameraIndex = idx;
    await _startCamera();
    _showControls();
  }

  void _joinMeeting() {
    if (_phase != _Phase.lobby) return;
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.joining);

    _joinTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _phase != _Phase.joining) return;
      setState(() {
        _phase = _Phase.inCall;
        _joinedAt = DateTime.now();
      });
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _seconds.value++;
      });
      _scheduleHideControls();
    });
  }

  Future<void> _requestLeave() async {
    if (_phase == _Phase.leaving || _dialogOpen) return;
    if (_phase == _Phase.lobby || _phase == _Phase.joining) {
      await _exit();
      return;
    }

    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _dialogOpen = true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave meeting?'),
        content: const Text('You can rejoin anytime with the same code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );

    _dialogOpen = false;
    if (!mounted) return;

    if (leave == true) {
      await _exit();
    } else {
      _showControls();
    }
  }

  Future<void> _exit() async {
    if (_phase == _Phase.leaving) return;

    _joinTimer?.cancel();
    _callTimer?.cancel();
    _hideTimer?.cancel();

    final result = MeetingResult(
      code: widget.meetingCode,
      title: widget.title,
      joined: _joinedAt != null,
      joinedAt: _joinedAt,
      durationSeconds: _seconds.value,
    );

    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.leaving);

    await _stopCamera();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _phase == _Phase.inCall) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    if (!mounted || _phase != _Phase.inCall) return;
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _toggleControls() {
    if (_phase != _Phase.inCall) return;
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _link));
    _snack('Meeting link copied');
  }

  void _shareLink() {
    Share.share('Join my Quorum meeting: $_link');
  }

  void _toggleMic() {
    HapticFeedback.selectionClick();
    setState(() => _micMuted = !_micMuted);
    _showControls();
  }

  void _toggleHand() {
    HapticFeedback.selectionClick();
    setState(() => _handRaised = !_handRaised);
    _showControls();
  }

  void _sendReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      _reactions.add(_Reaction(_reactionCounter++, emoji, _random.nextDouble()));
    });
  }

  Future<void> _showReactionPicker() async {
    const emojis = ['👍', '❤️', '😂', '👏', '🎉', '😮'];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final e in emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _sendReaction(e);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    _showControls();
  }

  Future<void> _showParticipants() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants (${_remote.length + 1})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _participantTile('You', muted: _micMuted, subtitle: 'Host'),
              for (final p in _remote) _participantTile(p.name, muted: p.muted),
              if (_remote.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No one else has joined yet.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Copy link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: _shareLink,
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Invite'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    _showControls();
  }

  Widget _participantTile(String name, {bool muted = false, String? subtitle}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.25),
        child: Text(
          name.characters.first.toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: Icon(
        muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        color: muted ? Colors.redAccent : Colors.white54,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0C10),
        body: switch (_phase) {
          _Phase.lobby => _buildLobby(),
          _Phase.leaving => _buildLeaving(),
          _ => _buildCall(),
        },
      ),
    );
  }

  Widget _buildLeaving() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Leaving...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _selfView() {
    final c = _camera;
    if (!_cameraOff && c != null && c.value.isInitialized) {
      final size = c.value.previewSize;
      if (size == null) return CameraPreview(c);

      final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
      return SizedBox.expand(
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: portrait ? size.height : size.width,
              height: portrait ? size.width : size.height,
              child: CameraPreview(c),
            ),
          ),
        ),
      );
    }

    final message = _permissionDenied
        ? 'Camera permission denied'
        : _cameraFailed
            ? 'Camera unavailable'
            : _cameraOff
                ? 'Camera is off'
                : 'Starting camera...';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E222A), Color(0xFF0F1115)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.25),
              child: const Icon(Icons.person_rounded,
                  size: 46, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 13),),
          ],
        ),
      ),
    );
  }

  Widget _buildLobby() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _requestLeave,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
            const Text(
              'Ready to join?',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _selfView(),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CallActionButton(
                                icon: _micMuted
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                isActive: _micMuted,
                                onPressed: () =>
                                    setState(() => _micMuted = !_micMuted),
                              ),
                              const SizedBox(width: 16),
                              CallActionButton(
                                icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                                isActive: _cameraOff,
                                onPressed: _toggleCamera,
                              ),
                              if (_cameras.length > 1) ...[
                                const SizedBox(width: 16),
                                CallActionButton(
                                  icon: Icons.cameraswitch_rounded,
                                  onPressed: _switchCamera,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_permissionDenied)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Camera access is off. You can still join with audio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: openAppSettings,
                      child: const Text('Settings'),
                    ),
                  ],
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _copyLink,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_rounded,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      widget.meetingCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded,
                        size: 14, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _joinMeeting,
                child: const Text(
                  'Join now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fade({required bool visible, required Offset hidden, required Widget child}) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : hidden,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: visible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }

  String _clock(int s) {
    final h = s ~/ 3600;
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$sec' : '$m:$sec';
  }

  Widget _buildCall() {
    final pad = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    final joining = _phase == _Phase.joining;
    final inCall = _phase == _Phase.inCall;
    final alone = _remote.isEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: alone ? _selfView() : _remoteStage(pad),
        ),

        IgnorePointer(
          child: Column(
            children: [
              Container(
                height: pad.top + 110,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: pad.bottom + 190,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!alone && inCall)
          Positioned.fill(
            child: DraggablePipView(
              topInset: pad.top + 72,
              bottomInset: pad.bottom + 120,
              child: _selfView(),
            ),
          ),

        if (joining) _buildJoiningOverlay(),

        if (inCall) ...[
          Positioned(
            top: pad.top + 8,
            left: 16,
            right: 16,
            child: _fade(
              visible: _controlsVisible,
              hidden: const Offset(0, -1),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _seconds,
                          builder: (context, s, child) => Text(
                            _clock(s),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _copyLink,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.meetingCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                    icon: Icon(
                      _speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _speakerOn = !_speakerOn);
                      _showControls();
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                    icon: const Icon(Icons.cameraswitch_rounded,
                        color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: pad.top + 64,
            left: 16,
            right: 16,
            child: Row(
              children: [
                if (_handRaised) _chip('✋', 'You raised your hand'),
                const Spacer(),
                if (_micMuted)
                  _chip(null, 'Muted', icon: Icons.mic_off_rounded),
              ],
            ),
          ),

          if (alone)
            Positioned(
              left: 16,
              right: 16,
              bottom: pad.bottom + 128,
              child: _fade(
                visible: _controlsVisible,
                hidden: const Offset(0, 0.6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("You're the only one here", style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Share the link so others can join.', style: TextStyle(color: Colors.white60, fontSize: 12.5),),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyLink,
                              icon: const Icon(Icons.link_rounded, size: 18),
                              label: const Text('Copy link'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              onPressed: _shareLink,
                              icon: const Icon(Icons.ios_share_rounded, size: 18),
                              label: const Text('Invite'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          IgnorePointer(
            child: Stack(
              children: [
                for (final r in _reactions)
                  TweenAnimationBuilder<double>(
                    key: ValueKey(r.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2400),
                    curve: Curves.easeOut,
                    onEnd: () {
                      if (mounted) {
                        setState(() => _reactions.removeWhere((x) => x.id == r.id));
                      }
                    },
                    builder: (context, t, child) => Positioned(
                      left: 16 + r.x * (size.width - 80),
                      bottom: pad.bottom + 120 + t * 320,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Text(r.emoji, style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: pad.bottom + 12,
            child: _fade(
              visible: _controlsVisible,
              hidden: const Offset(0, 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CallActionButton(
                        icon: _micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _micMuted ? 'Unmute' : 'Mic',
                        isActive: _micMuted,
                        onPressed: _toggleMic,
                      ),
                    ),
                    Expanded(
                      child: CallActionButton(
                        icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        label: 'Camera',
                        isActive: _cameraOff,
                        onPressed: _toggleCamera,
                      ),
                    ),
                    Expanded(
                      child: CallActionButton(
                        icon: Icons.emoji_emotions_outlined,
                        label: 'React',
                        onPressed: _showReactionPicker,
                      ),
                    ),
                    Expanded(
                      child: CallActionButton(
                        icon: _handRaised
                            ? Icons.back_hand_rounded
                            : Icons.back_hand_outlined,
                        label: 'Hand',
                        isActive: _handRaised,
                        onPressed: _toggleHand,
                      ),
                    ),
                    Expanded(
                      child: CallActionButton(
                        icon: Icons.people_alt_rounded,
                        label: 'People',
                        onPressed: _showParticipants,
                      ),
                    ),
                    Expanded(
                      child: CallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Leave',
                        backgroundColor: Colors.redAccent,
                        iconColor: Colors.white,
                        onPressed: _requestLeave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJoiningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 18),
              const Text('Joining meeting...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,),),
              const SizedBox(height: 4),
              Text(widget.meetingCode, style: const TextStyle(color: Colors.white54, fontSize: 13),),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _requestLeave,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String? emoji, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 14)),
          if (icon != null) Icon(icon, size: 14, color: Colors.redAccent),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _remoteStage(EdgeInsets pad) {
    return GridView.count(
      crossAxisCount: _remote.length == 1 ? 1 : 2,
      padding: EdgeInsets.fromLTRB(8, pad.top + 8, 8, pad.bottom + 100),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final p in _remote)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Text(p.name.characters.first.toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white),),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                if (p.muted)
                  const Positioned(
                    right: 12,
                    bottom: 10,
                    child: Icon(Icons.mic_off_rounded, color: Colors.redAccent, size: 18),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}