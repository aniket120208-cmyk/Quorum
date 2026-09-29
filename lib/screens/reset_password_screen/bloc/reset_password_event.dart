import 'package:equatable/equatable.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetOtpChanged extends ResetPasswordEvent {
  final String otp;
  const ResetOtpChanged(this.otp);
  @override
  List<Object?> get props => [otp];
}

class ResetNewPasswordChanged extends ResetPasswordEvent {
  final String password;
  const ResetNewPasswordChanged(this.password);
  @override
  List<Object?> get props => [password];
}

class ResetConfirmPasswordChanged extends ResetPasswordEvent {
  final String password;
  const ResetConfirmPasswordChanged(this.password);
  @override
  List<Object?> get props => [password];
}

class ResetToggleNewPasswordVisibility extends ResetPasswordEvent {}

class ResetToggleConfirmPasswordVisibility extends ResetPasswordEvent {}

class ResetPasswordSubmitted extends ResetPasswordEvent {}

class ResetOtpResendRequested extends ResetPasswordEvent {}

class ResetTimerTicked extends ResetPasswordEvent {
  final int duration;
  const ResetTimerTicked(this.duration);
  @override
  List<Object?> get props => [duration];
}
