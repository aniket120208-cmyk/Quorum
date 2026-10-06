import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'bloc/home_cubit.dart';
import 'package:quorum/api/api_client.dart';
import 'package:quorum/main.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        apiClient: context.read<ApiClient>(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<AuthRepository>().logout();
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
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
    final user = context.read<AuthRepository>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: BlocConsumer<HomeCubit, HomeState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, s) {
          if (s.status == HomeStatus.created && s.code != null) {
            _showLinkDialog(s.code!);
          }
          if (s.status == HomeStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.error ?? 'An unexpected error occurred')),
            );
          }
        },
        builder: (context, s) {
          final loading = s.status == HomeStatus.loading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hi, ${user?.name ?? 'there'}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () => context.read<HomeCubit>().createMeeting(),
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
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                      label: const Text('Log out'),
                    ),
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