import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/main.dart';
import 'package:share_plus/share_plus.dart';
import 'bloc/video_call_cubit.dart';
import 'meeting_room_screen.dart';
import 'models/meeting_history_item.dart';
import 'models/meeting_result.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoCallCubit()..loadHistory(),
      child: const _VideoCallLandingView(),
    );
  }
}

class _VideoCallLandingView extends StatefulWidget {
  const _VideoCallLandingView();
  @override
  State<_VideoCallLandingView> createState() => _VideoCallLandingViewState();
}

class _VideoCallLandingViewState extends State<_VideoCallLandingView> {
  final _codeCtrl = TextEditingController();
  static final _codePattern = RegExp(r'^[a-z0-9-]{3,}$');
  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openRoom(String code, {required String title}) async {
    FocusScope.of(context).unfocus();
    final cubit = context.read<VideoCallCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<MeetingResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MeetingRoomScreen(meetingCode: code, title: title),
      ),
    );

    if (result == null || !result.joined || cubit.isClosed) return;

    cubit.recordMeeting(result);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('You left the meeting • ${result.formattedDuration}')),
      );
  }

  String _extractCode(String input) {
    final segments = Uri.tryParse(input)
            ?.pathSegments
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final raw = segments.isNotEmpty ? segments.last : input;
    return raw.trim().toLowerCase();
  }

  void _handleJoin() {
    final input = _codeCtrl.text.trim();
    if (input.isEmpty) return;

    final code = _extractCode(input);
    if (!_codePattern.hasMatch(code)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("That doesn't look like a valid meeting code")),
        );
      return;
    }
    _codeCtrl.clear();
    _openRoom(code, title: 'Joined Meeting');
  }

  void _copyLink(String code) {
    Clipboard.setData(ClipboardData(text: 'https://quorum.app/meet/$code'));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Meeting link copied')));
  }

  void _showLinkDialog(String code) {
    final link = 'https://quorum.app/meet/$code';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Meeting ready', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this link with others, then start the meeting.',
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _copyLink(code),
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Share.share('Join my Quorum meeting: $link'),
            child: const Text('Share'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _openRoom(code, title: 'Instant Meeting');
            },
            child: const Text('Start now'),
          ),
        ],
      ),
    );
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    return '${dt.day}/${dt.month}/${dt.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<VideoCallCubit, VideoCallState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, s) {
          if (s.status == VideoCallStatus.created && s.code != null) {
            _showLinkDialog(s.code!);
          }
          if (s.status == VideoCallStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.error ?? 'An unexpected error occurred')),
            );
          }
        },
        builder: (context, s) {
          final loading = s.status == VideoCallStatus.loading;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Meetings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start a video call or join one with a code.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _buildHeroCard(loading),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Text(
                      'Recent meetings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (s.history.isNotEmpty)
                      Text(
                        '${s.history.length}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (s.history.isEmpty)
                  _buildEmptyState()
                else
                  for (var i = 0; i < s.history.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildHistoryTile(context, s.history[i], i),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(bool loading) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  loading ? null : () => context.read<VideoCallCubit>().createMeeting(),
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.videocam_rounded, color: Colors.white,),
              label: const Text(
                'New meeting',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: AppColors.surfaceBorder)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or join with a code',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: AppColors.surfaceBorder)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.go,
                  autocorrect: false,
                  onSubmitted: (_) => _handleJoin(),
                  decoration: InputDecoration(
                    hintText: 'abc-defg-hij or link',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.keyboard_rounded,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryLight),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _codeCtrl,
                builder: (context, value, child) {
                  final enabled = value.text.trim().isNotEmpty;
                  return SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: enabled ? _handleJoin : null,
                      child: const Text('Join'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'No meetings yet',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Meetings you join will show up here.',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, MeetingHistoryItem item, int index) {
    return Dismissible(
      key: ValueKey('${item.code}-${item.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        final cubit = context.read<VideoCallCubit>();
        cubit.removeMeeting(item);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Removed from history'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => cubit.restoreMeeting(item, index),
              ),
            ),
          );
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openRoom(item.code, title: item.title),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.code} • ${_formatWhen(item.timestamp)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            item.duration,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.link_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => _copyLink(item.code),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}