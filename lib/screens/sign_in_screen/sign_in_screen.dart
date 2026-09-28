import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_bloc.dart';
import 'package:quorum/screens/sign_up_screen/sign_up_screen/sign_up_screen.dart';
import '../widgets/corner_background_orb.dart';
import '../widgets/sign_in_form.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  static const Color darkBg = Color(0xFF0A0A12);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        authRepository: context.read<AuthRepository>(),
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            const CornerBackgroundOrb(
              backgroundColor: darkBg,
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const LoginFormCard(),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Create one',
                              style: TextStyle(
                                color: Color(0xFF6C63FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}