import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus {
  initial,
  submitting,
  success,
  failure,
}

class ForgotPasswordState extends Equatable {
  final String email;
  final String? emailError;
  final int resendCountdown;
  final ForgotPasswordStatus status;

  const ForgotPasswordState({
    this.email = '',
    this.emailError,
    this.resendCountdown = 30,
    this.status = ForgotPasswordStatus.initial,
  });

  bool get canResend => resendCountdown == 0;

  ForgotPasswordState copyWith({
    String? email,
    String? emailError,
    bool clearEmailError = false,
    int? resendCountdown,
    ForgotPasswordStatus? status,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      emailError: clearEmailError? null : emailError ?? this.emailError,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        email,
        emailError,
        resendCountdown,
        status,
      ];
}

