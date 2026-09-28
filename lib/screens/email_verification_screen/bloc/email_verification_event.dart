import 'package:equatable/equatable.dart';

abstract class EmailVerificationEvent extends Equatable {
  const EmailVerificationEvent();

  @override
  List<Object?> get props => [];
}

class OtpDigitChanged extends EmailVerificationEvent {
  final int index;
  final String digit;

  const OtpDigitChanged({required this.index, required this.digit});

  @override
  List<Object?> get props => [index, digit];
}

class VerifyOtpSubmitted extends EmailVerificationEvent {}

class ResendOtpSubmitted extends EmailVerificationEvent {}

class ResendOtpTimerTicked extends EmailVerificationEvent {
  final int duration;

  const ResendOtpTimerTicked(this.duration);

  @override
  List<Object?> get props => [duration];
}