import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/email_verification_screen/email_verification_screen.dart';
import 'package:quorum/screens/home_screen.dart';
import 'package:quorum/screens/onboarding_screen.dart';
import 'package:quorum/screens/role_selection_screens/bloc/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final repository = context.read<AuthRepository>();

    if (_failed) {
      setState(() => _failed = false);
    }

    try {
      final user = await repository.restoreSession();
      if (!mounted) return;
      if (user == null) {
        _go(const OnboardingScreen());
      } else if (!user.isEmailVerified) {
        _go(EmailVerificationScreen(email: user.email));
      } else if (await repository.needsRoleSelection()) {
        if (!mounted) return;
        _go(const UseQuorumScreen());
      } else {
        _go(const HomeScreen());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assets/logo.png',
              height: 140,
              width: 140,
            ),
            const SizedBox(height: 24),
            if (_failed) ...[
              const Text(
                "Couldn't connect. Please check your internet connection.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _restoreSession,
                child: const Text('Retry'),
              ),
            ] else
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}