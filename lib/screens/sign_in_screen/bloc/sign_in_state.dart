import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool isPasswordObscured;
  final String? emailError;
  final String? errorMessage;
  final bool isLoading;
  final bool isSuccess;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isPasswordObscured = true,
    this.emailError,
    this.errorMessage,
    this.isLoading = false,
    this.isSuccess = false,
  });

  bool get isValid => email.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isPasswordObscured,
    String? Function()? emailError,
    String? Function()? errorMessage,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      emailError: emailError != null ? emailError() : this.emailError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        isPasswordObscured,
        emailError,
        errorMessage,
        isLoading,
        isSuccess,
      ];
}