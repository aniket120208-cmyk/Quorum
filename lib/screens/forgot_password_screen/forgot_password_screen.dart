import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/reset_password_screen/reset_password_screen.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';

import 'bloc/forgot_password_bloc.dart';
import 'bloc/forgot_password_event.dart';
import 'bloc/forgot_password_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Widget? backgroundCircle;
  final String email;

  const ForgotPasswordScreen({
    super.key,
    this.backgroundCircle,
    this.email = '',
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;

  static const Color darkBg = Color(0xFF0D0F12);
  static const Color cardBorderColor = Color.fromARGB(98, 255, 255, 255);
  static const Color inputBg = Color(0xFF2A2D34);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color primaryBlue = Color(0xFF4743EB);
  static const Color linkBlue = Color(0xFF5D5FEF);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(
      text: widget.email,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(
        authRepository: context.read<AuthRepository>(),
        initialEmail: widget.email,
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            const CornerBackgroundOrb.topRight(backgroundColor: darkBg),
            const CornerBackgroundOrb.bottomLeft(backgroundColor: darkBg),
            if (widget.backgroundCircle != null)
              widget.backgroundCircle!,
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Forgot your password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ForgotPasswordBloc,
                        ForgotPasswordState>(
                      buildWhen: (previous, current) =>
                          previous.email != current.email,
                      builder: (context, state) {
                        return RichText(
                          text: TextSpan(
                            text:
                                "We'll send an email verification OTP to\n",
                            style: const TextStyle(
                              fontSize: 15,
                              color: textMuted,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: state.email.isEmpty
                                    ? 'example@gmail.com'
                                    : state.email,
                                style: const TextStyle(
                                  color: Color(0xFF6B82FA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: _buildPasswordIllustration(),
                    ),
                    const SizedBox(height: 36),
                    _buildFormCard(context),
                    SizedBox(height: 260,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordIllustration() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF2E3272),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF6B72D6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF2E3272),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF8F94FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '*****',
              style: TextStyle(
                color: Color(0xFF2E3272),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1.2,
        ),
      ),
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (previous, current) =>
            previous.status != ForgotPasswordStatus.success &&
            current.status == ForgotPasswordStatus.success,
        listener: (context, state) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: state.email.trim()),
            ),
          );
        },
        builder: (context, state) {
          final bloc = context.read<ForgotPasswordBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Work email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: state.emailError != null
                      ? Border.all(
                          color: errorRed,
                          width: 1.2,
                        )
                      : null,
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: Colors.white,
                  onChanged: (value) {
                    bloc.add(
                      ForgotPasswordEmailChanged(value),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'example@gmail.com',
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (state.emailError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.emailError!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Didn't receive the link?",
                    style: TextStyle(
                      color: textLight,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: state.canResend
                        ? () => bloc.add(
                              ResendLinkSubmitted(),
                            )
                        : null,
                    child: Text(
                      state.canResend
                          ? 'Resend'
                          : 'Resend (${state.resendCountdown}s)',
                      style: TextStyle(
                        color: state.canResend
                            ? linkBlue
                            : textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      state.status ==
                              ForgotPasswordStatus.submitting
                          ? null
                          : () => bloc.add(SendResetLinkSubmitted()),
                  child: state.status ==
                          ForgotPasswordStatus.submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Otp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
