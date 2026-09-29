import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';
import 'package:quorum/screens/widgets/otp_input.dart';

import 'bloc/reset_password_bloc.dart';
import 'bloc/reset_password_event.dart';
import 'bloc/reset_password_state.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  static const Color darkBg = Color(0xFF0D0F12);
  static const Color cardBorderColor = Color.fromARGB(98, 255, 255, 255);
  static const Color inputBg = Color(0xFF2A2D34);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color primaryBlue = Color(0xFF4743EB);
  static const Color linkBlue = Color(0xFF5D5FEF);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordBloc(
        authRepository: context.read<AuthRepository>(),
        email: email,
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            const CornerBackgroundOrb.topRight(backgroundColor: darkBg),
            const CornerBackgroundOrb.bottomLeft(backgroundColor: darkBg),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Reset your password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: "We've sent a 6-digit code to\n",
                        style: const TextStyle(
                          fontSize: 15,
                          color: textMuted,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: email,
                            style: const TextStyle(
                              color: Color(0xFF6B82FA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildFormCard(context),
                    const SizedBox(height: 170),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.2),
      ),
      child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
        listenWhen: (previous, current) =>
            previous.status != ResetPasswordStatus.success &&
            current.status == ResetPasswordStatus.success,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successful. Please sign in.'),
            ),
          );
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.pop();
        },
        builder: (context, state) {
          final bloc = context.read<ResetPasswordBloc>();
          final isFailure = state.status == ResetPasswordStatus.failure;
          final isSubmitting = state.status == ResetPasswordStatus.submitting;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textLight,
                ),
              ),
              const SizedBox(height: 8),
              OtpInput(
                hasError: isFailure,
                onChanged: (otp) => bloc.add(ResetOtpChanged(otp)),
              ),
              const SizedBox(height: 18),
              const Text(
                'New password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textLight,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                hintText: 'Create a strong password',
                obscureText: state.obscureNewPassword,
                hasError: false,
                onToggle: () => bloc.add(ResetToggleNewPasswordVisibility()),
                onChanged: (v) => bloc.add(ResetNewPasswordChanged(v)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Confirm password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textLight,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                hintText: 'Confirm password',
                obscureText: state.obscureConfirmPassword,
                hasError: state.passwordError != null,
                onToggle: () =>
                    bloc.add(ResetToggleConfirmPasswordVisibility()),
                onChanged: (v) => bloc.add(ResetConfirmPasswordChanged(v)),
              ),
              if (state.passwordError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.passwordError!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (state.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.message!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(color: textLight, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: state.canResend
                        ? () => bloc.add(ResetOtpResendRequested())
                        : null,
                    child: Text(
                      state.canResend
                          ? 'Resend'
                          : 'Resend (${state.resendCountdown}s)',
                      style: TextStyle(
                        color: state.canResend ? linkBlue : textMuted,
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
                  onPressed: isSubmitting
                      ? null
                      : () => bloc.add(ResetPasswordSubmitted()),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Reset password',
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

  Widget _buildPasswordField({
    required String hintText,
    required bool obscureText,
    required bool hasError,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: hasError ? Border.all(color: errorRed, width: 1.2) : null,
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: textMuted, fontSize: 14),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: textMuted,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
