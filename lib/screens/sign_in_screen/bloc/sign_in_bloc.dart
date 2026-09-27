import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_event.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(
        email: event.email,
        emailError: () => null,
        errorMessage: () => null,
      ));
    });

    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(
        password: event.password,
        errorMessage: () => null,
      ));
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
    });

    on<SubmitLogin>((event, emit) async {
      if (!state.isValid) return;

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final isValidEmail = emailRegex.hasMatch(state.email.trim());

      if (!isValidEmail) {
        emit(state.copyWith(emailError: () => 'Invalid email address'));
        return;
      }

      emit(state.copyWith(
        isLoading: true,
        emailError: () => null,
        errorMessage: () => null,
      ));

      try {
        await Future.delayed(const Duration(seconds: 1));

        const loginSucceeded = false;
        if (!loginSucceeded) {
          throw Exception('Invalid email or password');
        }

        emit(state.copyWith(isLoading: false));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => e.toString().replaceFirst('Exception: ', ''),
        ));
      }
    });
  }
}