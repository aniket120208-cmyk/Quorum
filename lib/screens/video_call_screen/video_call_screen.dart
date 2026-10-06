import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'bloc/video_call_cubit.dart';
import 'package:quorum/api/api_client.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoCallCubit(
        apiClient: context.read<ApiClient>(),
      ),
      child: const _VideoCallView(),
    );
  }
}

class _VideoCallView extends StatefulWidget {
  const _VideoCallView();

  @override
  State<_VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<_VideoCallView> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _showLinkDialog(String code) {
    final link = '${1244}/meet/$code';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Meeting ready'),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Share.share('Join my meeting: $link'),
            child: const Text('Share'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.push('/meet/$code');
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _handleJoin() {
    final input = _codeCtrl.text.trim();
    if (input.isEmpty) return;

    final code = Uri.tryParse(input)?.pathSegments.lastWhere(
          (seg) => seg.isNotEmpty,
          orElse: () => '',
        ) ?? input;

    if (code.isNotEmpty) {
      context.push('/meet/$code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet'),
      ),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () => context.read<VideoCallCubit>().createMeeting(),
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.video_call),
                    label: Text(loading ? 'Creating...' : 'New meeting'),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Meeting code or link',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleJoin(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _handleJoin,
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}