import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_bloc.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_event.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_state.dart';
import 'package:quorum/screens/role_selection_screens/bloc/role_selection_screen.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email,});
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color darkBg = Color(0xFF0D0F12);
  static const Color cardBorderColor = Color.fromARGB(98, 255, 255, 255);
  static const Color inputBg = Color(0xFF2A2D34);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color primaryBlue = Color(0xFF4743EB);
  static const Color linkBlue = Color(0xFF5D5FEF);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmailVerificationBloc(
        authRepository: context.read<AuthRepository>(),
        email: widget.email,
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CornerBackgroundOrb.topRight(
              backgroundColor: darkBg,
            ),
            const CornerBackgroundOrb.bottomLeft(
              backgroundColor: darkBg,
            ),
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
                      'Verify your email',
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
                            text: widget.email,
                            style: const TextStyle(
                              color: Color(0xFF6B82FA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    Center(
                      child: _buildMailIllustration(),
                    ),

                    const SizedBox(height: 36),
                    _buildOtpCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailIllustration() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            child: Container(
              width: 68,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 2.5,
                    color: const Color(0xFFCBD5E1),
                  ),
                  Container(
                    height: 2.5,
                    color: const Color(0xFFCBD5E1),
                  ),
                  Container(
                    height: 2.5,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 88,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF4743EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _MailEnvelopePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1.2,
        ),
      ),
      child: BlocConsumer<EmailVerificationBloc,
          EmailVerificationState>(
        listenWhen: (previous, current) =>
            previous.status != OtpStatus.success &&
            current.status == OtpStatus.success,
        listener: (context, state) {
          Future.delayed(
            const Duration(milliseconds: 900),
            () {
              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const UseQuorumScreen(),
                ),
                (route) => false,
              );
            },
          );
        },
        builder: (context, state) {
          final bloc =
              context.read<EmailVerificationBloc>();

          final isSuccess =
              state.status == OtpStatus.success;

          final isFailure =
              state.status == OtpStatus.failure;

          Color borderColor = cardBorderColor;

          if (isSuccess) {
            borderColor = successGreen;
          }

          if (isFailure) {
            borderColor = errorRed;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int index = 0; index < 6; index++) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _buildOtpBox(
                          index: index,
                          borderColor: borderColor,
                          isSuccess: isSuccess,
                          isFailure: isFailure,

                          onChanged: (val) {
                            if (val.length > 1) {
                              final digits =
                                  val.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );

                              for (
                                int i = 0;
                                i < digits.length &&
                                    index + i < 6;
                                i++
                              ) {
                                final boxIndex =
                                    index + i;

                                final digit =
                                    digits[i];

                                _controllers[boxIndex]
                                    .text = digit;

                                bloc.add(
                                  OtpDigitChanged(
                                    index: boxIndex,
                                    digit: digit,
                                  ),
                                );
                              }

                              final nextIndex =
                                  index + digits.length;

                              if (nextIndex < 6) {
                                _focusNodes[nextIndex]
                                    .requestFocus();
                              } else {
                                _focusNodes[5]
                                    .requestFocus();
                              }

                              return;
                            }

                            bloc.add(
                              OtpDigitChanged(
                                index: index,
                                digit: val,
                              ),
                            );

                            if (val.isNotEmpty &&
                                index < 5) {
                              _focusNodes[index + 1]
                                  .requestFocus();
                            }

                            if (val.isEmpty &&
                                index > 0) {
                              _focusNodes[index - 1]
                                  .requestFocus();
                            }
                          },
                        ),
                      ),
                    ),

                    if (index < 5)
                      const SizedBox(width: 8),
                  ],
                ],
              ),

              if (state.message != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.message!,
                  style: TextStyle(
                    color: isSuccess
                        ? successGreen
                        : errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (!isSuccess) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        "Didn't receive the code?",
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: state.canResend
                          ? () => bloc.add(
                                ResendOtpSubmitted(),
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
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),

                    onPressed:
                        state.status ==
                                OtpStatus.submitting
                            ? null
                            : () => bloc.add(
                                  VerifyOtpSubmitted(),
                                ),

                    child:
                        state.status ==
                                OtpStatus.submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildOtpBox({
    required int index,
    required Color borderColor,
    required bool isSuccess,
    required bool isFailure,
    required ValueChanged<String> onChanged,
  }) {
    Color textColor = Colors.white;

    if (isSuccess) {
      textColor = successGreen;
    }

    if (isFailure) {
      textColor = errorRed;
    }

    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: Colors.white,

          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],

          decoration: InputDecoration(
            hintText: 'X',
            hintStyle: TextStyle(
              color: isFailure
                  ? errorRed.withValues(alpha: 0.6)
                  : (isSuccess
                      ? successGreen.withValues(alpha: 0.6)
                      : textMuted),
              fontSize: 14,
            ),
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MailEnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3835C4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(
        size.width / 2,
        size.height * 0.55,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}