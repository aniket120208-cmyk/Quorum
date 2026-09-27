import 'package:flutter_bloc/flutter_bloc.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  SignUpBloc() : super(const SignUpState()) {
    on<FullNameChanged>((event, emit) {
      final name = event.fullName.trim();

      emit(
        state.copyWith(
          fullName: event.fullName,
          nameError: name.isEmpty ? 'Please enter your name.' : null,
          clearNameError: name.isNotEmpty,
        ),
      );
    });

    on<WorkEmailChanged>((event, emit) {
      final email = event.email.trim();
      String? error;

      if (email.isNotEmpty && !_emailRegExp.hasMatch(email)) {
        error = 'Please enter a valid email address.';
      }

      emit(
        state.copyWith(
          email: event.email,
          emailError: error,
          clearEmailError: error == null,
        ),
      );
    });

    on<PasswordChanged>((event, emit) {
      final isMismatch = state.confirmPassword.isNotEmpty &&
          event.password != state.confirmPassword;

      emit(
        state.copyWith(
          password: event.password,
          passwordError:
              isMismatch ? 'The password does not match.' : null,
          clearPasswordError: !isMismatch,
        ),
      );
    });

    on<ConfirmPasswordChanged>((event, emit) {
      final isMismatch = event.confirmPassword != state.password;

      emit(
        state.copyWith(
          confirmPassword: event.confirmPassword,
          passwordError:
              isMismatch ? 'The password does not match.' : null,
          clearPasswordError: !isMismatch,
        ),
      );
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(
        state.copyWith(
          obscurePassword: !state.obscurePassword,
        ),
      );
    });

    on<ToggleConfirmPasswordVisibility>((event, emit) {
      emit(
        state.copyWith(
          obscureConfirmPassword: !state.obscureConfirmPassword,
        ),
      );
    });

    on<SignUpSubmitted>((event, emit) async {
      final name = state.fullName.trim();
      final email = state.email.trim();

      String? nameErr;
      String? emailErr;
      String? passwordErr;

      if (name.isEmpty) {
        nameErr = 'Please enter your name.';
      }

      if (email.isEmpty || !_emailRegExp.hasMatch(email)) {
        emailErr = 'Please enter a valid email address.';
      }

      if (state.password != state.confirmPassword) {
        passwordErr = 'The password does not match.';
      }

      if (nameErr != null ||
          emailErr != null ||
          passwordErr != null) {
        emit(
          state.copyWith(
            nameError: nameErr,
            emailError: emailErr,
            passwordError: passwordErr,
          ),
        );
        return;
      }

      if (state.password.isEmpty) {
        return;
      }

      emit(
        state.copyWith(
          status: SignUpStatus.submitting,
          clearNameError: true,
          clearEmailError: true,
          clearPasswordError: true,
        ),
      );

      await Future.delayed(
        const Duration(seconds: 1),
      );

      emit(
        state.copyWith(
          status: SignUpStatus.success,
        ),
      );
    });
  }
}
