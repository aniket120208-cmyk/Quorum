import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/email_verification_screen/email_verification_screen.dart';
import 'package:quorum/screens/sign_up_screen/bloc/sign_up_bloc.dart';
import 'package:quorum/screens/sign_up_screen/bloc/sign_up_event.dart';
import 'package:quorum/screens/sign_up_screen/bloc/sign_up_state.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';
import 'package:quorum/utils/validators.dart';

class SignUpScreen extends StatelessWidget {
  final Widget? backgroundCircle;

  const SignUpScreen({
    super.key,
    this.backgroundCircle,
  });

  static const Color darkBg = Color(0xFF0D0F12);
  static const Color cardBorderColor = Color(0xFF282C37);
  static const Color inputBg = Color(0xFF2A2D34);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color primaryBlue = Color(0xFF4743EB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SignUpBloc(authRepository: context.read<AuthRepository>()),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            const CornerBackgroundOrb.topRight(backgroundColor: darkBg),
            const CornerBackgroundOrb.bottomLeft(backgroundColor: darkBg),
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
                      'Create your account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start your journey with Quorum',
                      style: TextStyle(
                        fontSize: 15,
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildFormCard(context),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an ',
                            style: TextStyle(
                              color: textLight,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'account ? ',
                            style: TextStyle(
                              color: textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF5D5FEF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
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
        border: Border.all(
          color: const Color.fromARGB(98, 255, 255, 255),
          width: 1.2,
        ),
      ),
      child: BlocConsumer<SignUpBloc, SignUpState>(
        listenWhen: (previous, current) =>
            previous.status != SignUpStatus.success &&
            current.status == SignUpStatus.success,
        listener: (context, state) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: state.email.trim()),
            ),
          );
        },
        builder: (context, state) {
          final bloc = context.read<SignUpBloc>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Full name'),
              const SizedBox(height: 8),
              _buildInputField(
                hintText: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                hasError: state.nameError != null,
                onChanged: (val) => bloc.add(FullNameChanged(val)),
              ),
              if (state.nameError != null) ...[
                const SizedBox(height: 8),
                _buildErrorText(state.nameError!),
              ],
              const SizedBox(height: 18),
              _buildFieldLabel('Work email'),
              const SizedBox(height: 8),
              _buildInputField(
                hintText: 'example@gmail.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: emailInputFormatters,
                hasError: state.emailError != null,
                onChanged: (val) => bloc.add(WorkEmailChanged(val)),
              ),
              if (state.emailError != null) ...[
                const SizedBox(height: 8),
                _buildErrorText(state.emailError!),
              ],
              const SizedBox(height: 18),
              _buildFieldLabel('Password'),
              const SizedBox(height: 8),
              _buildInputField(
                hintText: 'Create a strong password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: state.obscurePassword,
                hasError: state.passwordFormatError != null,
                onToggleVisibility: () => bloc.add(TogglePasswordVisibility()),
                onChanged: (val) => bloc.add(PasswordChanged(val)),
              ),
              const SizedBox(height: 8),
              _buildPasswordFeedback(state.password),
              const SizedBox(height: 18),
              _buildFieldLabel('Confirm Password'),
              const SizedBox(height: 8),
              _buildInputField(
                hintText: 'Confirm password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: state.obscureConfirmPassword,
                hasError: state.passwordError != null,
                onToggleVisibility: () =>
                    bloc.add(ToggleConfirmPasswordVisibility()),
                onChanged: (val) => bloc.add(ConfirmPasswordChanged(val)),
              ),
              if (state.passwordError != null) ...[
                const SizedBox(height: 8),
                _buildErrorText(state.passwordError!),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorText(state.errorMessage!),
              ],
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
                  onPressed: state.status == SignUpStatus.submitting
                      ? null
                      : () => bloc.add(SignUpSubmitted()),
                  child: state.status == SignUpStatus.submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create account',
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

  Widget _buildPasswordFeedback(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    final List<String> missing = [];
    if (!PasswordRules.hasMinLength(password)) missing.add('8+ chars');
    if (!PasswordRules.hasUppercase(password)) missing.add('uppercase');
    if (!PasswordRules.hasLowercase(password)) missing.add('lowercase');
    if (!PasswordRules.hasSpecial(password)) missing.add('symbol');

    final int score = 4 - missing.length;
    Color barColor;
    String scoreLabel;

    switch (score) {
      case 1:
        barColor = errorRed;
        scoreLabel = 'Weak';
        break;
      case 2:
        barColor = const Color(0xFFF59E0B);
        scoreLabel = 'Fair';
        break;
      case 3:
        barColor = const Color(0xFF3B82F6);
        scoreLabel = 'Good';
        break;
      case 4:
        barColor = successGreen;
        scoreLabel = 'Strong';
        break;
      default:
        barColor = inputBg;
        scoreLabel = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: index < score ? barColor : inputBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              scoreLabel,
              style: TextStyle(
                color: barColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: missing.map((rule) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2228),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: errorRed.withAlpha(120),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Needs $rule',
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorText(String message) {
    return Text(
      message,
      style: const TextStyle(
        color: errorRed,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textLight,
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    bool hasError = false,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: hasError
            ? Border.all(
                color: errorRed,
                width: 1.2,
              )
            : null,
      ),
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: textMuted,
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textMuted,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}