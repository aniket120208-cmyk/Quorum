import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_client.dart';
import 'package:quorum/token_storage.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/sign_in_screen.dart';
import 'package:quorum/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository =
      AuthRepository(api: apiClient, tokenStorage: tokenStorage);
  runApp(Quorum(authRepository: authRepository));
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF15151F);
  static const Color surfaceBorder = Color(0xFF2A2A38);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9C9CAD);

  static const Color primary = Color(0xFF6F5EF6);
  static const Color primaryLight = Color(0xFF8B7DFA);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const RadialGradient backgroundGlow = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.2,
    colors: [Color(0xFF241E42), background],
  );
}

class Quorum extends StatefulWidget {
  const Quorum({super.key, required this.authRepository});
  final AuthRepository authRepository;
  @override
  State<Quorum> createState() => _QuorumState();
}

class _QuorumState extends State<Quorum> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<void>? _sessionExpiredSub;

  @override
  void initState() {
    super.initState();

    _sessionExpiredSub = widget.authRepository.sessionExpired.listen((_) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Your session expired. Please sign in again.')),
      );
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>.value(
      value: widget.authRepository,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
      ),
    );
  }
}