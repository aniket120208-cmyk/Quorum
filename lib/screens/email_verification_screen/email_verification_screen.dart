import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_bloc.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_event.dart';
import 'package:quorum/screens/email_verification_screen/bloc/email_verification_state.dart';
import 'package:quorum/screens/widgets/corner_background_orb.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key,required this.email,});
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
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

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
      create: (_) => EmailVerificationBloc(),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            CornerBackgroundOrb(backgroundColor: darkBg),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    Center(child: _buildMailIllustration()),
                    const SizedBox(height: 36),
                    _buildOtpCard(),
                    const SizedBox(height: 260,)
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
                  Container(height: 2.5, color: const Color(0xFFCBD5E1)),
                  Container(height: 2.5, color: const Color(0xFFCBD5E1)),
                  Container(height: 2.5, color: const Color(0xFFCBD5E1)),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.2),
      ),
      child: BlocBuilder<EmailVerificationBloc, EmailVerificationState>(
        builder: (context, state) {
          final bloc = context.read<EmailVerificationBloc>();
          final isSuccess = state.status == OtpStatus.success;
          final isFailure = state.status == OtpStatus.failure;

          Color borderColor = const Color.fromARGB(98, 255, 255, 255);
          if (isSuccess) borderColor = successGreen;
          if (isFailure) borderColor = errorRed;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return _buildOtpBox(
                    index: index,
                    borderColor: borderColor,
                    isSuccess: isSuccess,
                    isFailure: isFailure,
                    onChanged: (val) {
                      bloc.add(OtpDigitChanged(index: index, digit: val));
                      if (val.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (val.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  );
                }),
              ),
              if (state.message != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.message!,
                  style: TextStyle(
                    color: isSuccess ? successGreen : errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (!isSuccess) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Didn't receive the code?",
                      style: TextStyle(color: textLight, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: state.canResend
                          ? () => bloc.add(ResendOtpSubmitted())
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
                    onPressed: state.status == OtpStatus.submitting
                        ? null
                        : () => bloc.add(VerifyOtpSubmitted()),
                    child: state.status == OtpStatus.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
    if (isSuccess) textColor = successGreen;
    if (isFailure) textColor = errorRed;

    return Container(
      width: 44,
      height: 48,
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
          maxLength: 1,
          cursorColor: Colors.white,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      ..lineTo(size.width / 2, size.height * 0.55)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}