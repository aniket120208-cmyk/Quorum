import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:quorum/screens/home_screen.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_bloc.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_event.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_state.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({super.key});

  static const Color cardBorder = Color(0xFF2A2E3B);
  static const Color inputBg = Color(0xFF2B2E33);
  static const Color primaryButton = Color(0xFF4C44EC);
  static const Color errorRed = Color(0xFFE24C4C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(98, 255, 255, 255), width: 1.2),
      ),
      child: BlocConsumer<LoginBloc, LoginState>(
        listenWhen: (previous, current) =>
            !previous.isSuccess && current.isSuccess,
        listener: (context, state) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        builder: (context, state) {
          final hasError = state.emailError != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email address',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasError ? errorRed : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  onChanged: (val) =>
                      context.read<LoginBloc>().add(EmailChanged(val)),
                  style: TextStyle(
                    color: hasError ? errorRed : Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'example@gmail.com',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: hasError
                          ? errorRed
                          : Colors.white.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 6),
                Text(
                  state.emailError!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  obscureText: state.isPasswordObscured,
                  onChanged: (val) =>
                      context.read<LoginBloc>().add(PasswordChanged(val)),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => context
                          .read<LoginBloc>()
                          .add(TogglePasswordVisibility()),
                      child: Icon(
                        state.isPasswordObscured? Icons.visibility_off_outlined: Icons.visibility_outlined,
                        size: 18,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen(
                        email: state.email,
                      ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password ?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<LoginBloc>().add(SubmitLogin()),
                  style: state.isValid ?
                  ElevatedButton.styleFrom(
                    backgroundColor: primaryButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ): ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C44EC).withOpacity(0.35),
                    foregroundColor: Colors.white.withOpacity(0.38),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 15,
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