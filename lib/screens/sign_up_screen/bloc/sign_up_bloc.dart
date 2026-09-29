import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/utils/validators.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final AuthRepository _authRepository;

  SignUpBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const SignUpState()) {
    on<FullNameChanged>((event, emit) {
      final error = validateName(event.fullName);

      emit(
        state.copyWith(
          fullName: event.fullName,
          nameError: error,
          clearNameError: error == null,
          clearErrorMessage: true,
        ),
      );
    });

    on<WorkEmailChanged>((event, emit) {
      final email = event.email.trim();
      String? error;

      if (email.isNotEmpty && !isValidEmail(email)) {
        error = 'Please enter a valid email address.';
      }

      emit(
        state.copyWith(
          email: event.email,
          emailError: error,
          clearEmailError: error == null,
          clearErrorMessage: true,
        ),
      );
    });

    on<PasswordChanged>((event, emit) {
      final formatError =
          event.password.isEmpty ? null : validatePassword(event.password);
      final isMismatch = state.confirmPassword.isNotEmpty &&
          event.password != state.confirmPassword;

      emit(
        state.copyWith(
          password: event.password,
          passwordFormatError: formatError,
          clearPasswordFormatError: formatError == null,
          passwordError: isMismatch ? 'The password does not match.' : null,
          clearPasswordError: !isMismatch,
          clearErrorMessage: true,
        ),
      );
    });

    on<ConfirmPasswordChanged>((event, emit) {
      final isMismatch = event.confirmPassword != state.password;

      emit(
        state.copyWith(
          confirmPassword: event.confirmPassword,
          passwordError: isMismatch ? 'The password does not match.' : null,
          clearPasswordError: !isMismatch,
          clearErrorMessage: true,
        ),
      );
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
    });

    on<ToggleConfirmPasswordVisibility>((event, emit) {
      emit(
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword),
      );
    });

    on<SignUpSubmitted>((event, emit) async {
      if (state.status == SignUpStatus.submitting) return;

      final name = state.fullName.trim();
      final email = state.email.trim();

      final nameErr = validateName(name);
      final emailErr =
          isValidEmail(email) ? null : 'Please enter a valid email address.';
      final formatErr = validatePassword(state.password);
      final passwordErr = state.password != state.confirmPassword
          ? 'The password does not match.'
          : null;

      if (nameErr != null ||
          emailErr != null ||
          formatErr != null ||
          passwordErr != null) {
        emit(
          state.copyWith(
            nameError: nameErr,
            emailError: emailErr,
            passwordFormatError: formatErr,
            passwordError: passwordErr,
            clearNameError: nameErr == null,
            clearEmailError: emailErr == null,
            clearPasswordFormatError: formatErr == null,
            clearPasswordError: passwordErr == null,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SignUpStatus.submitting,
          clearNameError: true,
          clearEmailError: true,
          clearPasswordFormatError: true,
          clearPasswordError: true,
          clearErrorMessage: true,
        ),
      );

      try {
        await _authRepository.register(
          name: name,
          email: email,
          password: state.password,
        );
        emit(state.copyWith(status: SignUpStatus.success));
      } on ApiException catch (e) {
        if (e.statusCode == 409) {
          emit(state.copyWith(status: SignUpStatus.failure, emailError: e.message));
        } else {
          emit(state.copyWith(status: SignUpStatus.failure, errorMessage: e.message));
        }
      } catch (e) {
        emit(
          state.copyWith(
            status: SignUpStatus.failure,
            errorMessage: messageFromError(e),
          ),
        );
      }
    });
  }
}