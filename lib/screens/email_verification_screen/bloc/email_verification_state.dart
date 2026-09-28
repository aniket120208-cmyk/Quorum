import 'package:equatable/equatable.dart';

enum OtpStatus { initial, submitting, success, failure }

class EmailVerificationState extends Equatable {
  final List<String> otpDigits;
  final int resendCountdown;
  final OtpStatus status;
  final String? message;

  const EmailVerificationState({
    this.otpDigits = const ['', '', '', '', '', ''],
    this.resendCountdown = 15,
    this.status = OtpStatus.initial,
    this.message,
  });

  bool get canResend => resendCountdown == 0;
  bool get isFilled => otpDigits.every((d) => d.trim().isNotEmpty);
  String get fullOtp => otpDigits.join();

  EmailVerificationState copyWith({
    List<String>? otpDigits,
    int? resendCountdown,
    OtpStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return EmailVerificationState(
      otpDigits: otpDigits ?? this.otpDigits,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        otpDigits,
        resendCountdown,
        status,
        message,
      ];
}