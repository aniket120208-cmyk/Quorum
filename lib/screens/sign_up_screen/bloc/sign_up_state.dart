import 'package:equatable/equatable.dart';

enum SignUpStatus {
  initial,
  submitting,
  success,
  failure,
}

class SignUpState extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? nameError;
  final String? emailError;
  final String? passwordFormatError;
  final String? passwordError;
  final String? errorMessage;
  final SignUpStatus status;

  const SignUpState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.nameError,
    this.emailError,
    this.passwordFormatError,
    this.passwordError,
    this.errorMessage,
    this.status = SignUpStatus.initial,
  });

  SignUpState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? nameError,
    String? emailError,
    String? passwordFormatError,
    String? passwordError,
    String? errorMessage,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordFormatError = false,
    bool clearPasswordError = false,
    bool clearErrorMessage = false,
    SignUpStatus? status,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordFormatError: clearPasswordFormatError
          ? null
          : (passwordFormatError ?? this.passwordFormatError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        email,
        password,
        confirmPassword,
        obscurePassword,
        obscureConfirmPassword,
        nameError,
        emailError,
        passwordFormatError,
        passwordError,
        errorMessage,
        status,
      ];
}