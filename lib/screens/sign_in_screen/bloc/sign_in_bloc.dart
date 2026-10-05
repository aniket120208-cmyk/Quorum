import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/utils/validators.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_event.dart';
import 'package:quorum/screens/sign_in_screen/bloc/sign_in_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState()) {
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
      if (!state.isValid || state.isLoading) return;

      if (!isValidEmail(state.email)) {
        emit(state.copyWith(emailError: () => 'Invalid email address'));
        return;
      }

      emit(state.copyWith(
        isLoading: true,
        emailError: () => null,
        errorMessage: () => null,
      ));

      try {
        await _authRepository.login(
          email: state.email,
          password: state.password,
        );
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } on ApiException catch (e) {
        final unverified = e.statusCode == 403 &&
            e.message.toLowerCase().contains('verif');
        emit(state.copyWith(
          isLoading: false,
          needsVerification: unverified,
          errorMessage: () => unverified ? null : e.message,
        ));
        if (unverified) emit(state.copyWith(needsVerification: false));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => messageFromError(e),
        ));
      }
    });
  }
}