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
  final String? passwordError;
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
    this.passwordError,
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
    String? passwordError,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    SignUpStatus? status,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword:
          obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      nameError:
          clearNameError ? null : (nameError ?? this.nameError),
      emailError:
          clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError
              ? null
              : (passwordError ?? this.passwordError),
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
        passwordError,
        status,
      ];
}
