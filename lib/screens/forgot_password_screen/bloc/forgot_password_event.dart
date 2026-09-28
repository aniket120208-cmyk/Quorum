import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();
  @override
  List<Object?> get props => [];
}

class ForgotPasswordEmailChanged extends ForgotPasswordEvent {
  final String email;
  const ForgotPasswordEmailChanged(this.email);
  @override
  List<Object?> get props => [email];
}

class SendResetLinkSubmitted extends ForgotPasswordEvent {}

class ResendLinkSubmitted extends ForgotPasswordEvent {}

class ResendTimerTicked extends ForgotPasswordEvent {
  final int duration;

  const ResendTimerTicked(this.duration);

  @override
  List<Object?> get props => [duration];
}