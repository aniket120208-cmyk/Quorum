import 'package:equatable/equatable.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();
  @override
  List<Object?> get props => [];
}

class FullNameChanged extends SignUpEvent {
  final String fullName;
  const FullNameChanged(this.fullName);
  @override
  List<Object?> get props => [fullName];
}

class WorkEmailChanged extends SignUpEvent {
  final String email;
  const WorkEmailChanged(this.email);
  @override
  List<Object?> get props => [email];
}

class PasswordChanged extends SignUpEvent {
  final String password;
  const PasswordChanged(this.password);
  @override
  List<Object?> get props => [password];
}

class ConfirmPasswordChanged extends SignUpEvent {
  final String confirmPassword;
  const ConfirmPasswordChanged(this.confirmPassword);
  @override
  List<Object?> get props => [confirmPassword];
}

class TogglePasswordVisibility extends SignUpEvent {}

class ToggleConfirmPasswordVisibility extends SignUpEvent {}

class SignUpSubmitted extends SignUpEvent {}