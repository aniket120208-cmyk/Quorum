import 'package:equatable/equatable.dart';

enum ResetPasswordStatus { initial, submitting, success, failure }

class ResetPasswordState extends Equatable {
  final String otp;
  final String newPassword;
  final String confirmPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final String? passwordFormatError;
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
    this.passwordFormatError,
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
    String? passwordFormatError,
    String? passwordError,
    String? message,
    int? resendCountdown,
    ResetPasswordStatus? status,
    bool clearPasswordFormatError = false,
    bool clearPasswordError = false,
    bool clearMessage = false,
  }) {
    return ResetPasswordState(
      otp: otp ?? this.otp,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscureNewPassword:
          obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      passwordFormatError: clearPasswordFormatError
          ? null
          : (passwordFormatError ?? this.passwordFormatError),
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
        passwordFormatError,
        passwordError,
        message,
        resendCountdown,
        status,
      ];
}