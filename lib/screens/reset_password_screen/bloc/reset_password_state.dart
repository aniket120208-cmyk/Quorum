import 'package:equatable/equatable.dart';

enum ResetPasswordStatus { initial, submitting, success, failure }

class ResetPasswordState extends Equatable {
  final String otp;
  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final String? passwordError;
  final String? message;
  final int resendCountdown;
  final ResetPasswordStatus status;

  const ResetPasswordState({
    this.otp = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.passwordError,
    this.message,
    this.resendCountdown = 15,
    this.status = ResetPasswordStatus.initial,
  });

  bool get canResend => resendCountdown == 0;

  ResetPasswordState copyWith({
    String? otp,
    String? newPassword,
    String? confirmPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    String? passwordError,
    String? message,
    int? resendCountdown,
    ResetPasswordStatus? status,
    bool clearPasswordError = false,
    bool clearMessage = false,
  }) {
    return ResetPasswordState(
      otp: otp ?? this.otp,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      message: clearMessage ? null : (message ?? this.message),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        otp,
        newPassword,
        confirmPassword,
        obscureNewPassword,
        obscureConfirmPassword,
        passwordError,
        message,
        resendCountdown,
        status,
      ];
}
