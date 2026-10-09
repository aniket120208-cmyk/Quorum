import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/repositories/auth_repository.dart';

import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final AuthRepository _authRepository;
  StreamSubscription<int>? _timerSubscription;

  ForgotPasswordBloc({
    required AuthRepository authRepository,
    String initialEmail = '',
  })  : _authRepository = authRepository,
        super(
          ForgotPasswordState(
            email: initialEmail,
          ),
        ) {
    _startCountdown();

    on<ForgotPasswordEmailChanged>((event, emit) {
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

    on<ResendTimerTicked>((event, emit) {
      emit(
        state.copyWith(
          resendCountdown: event.duration,
        ),
      );
    });

    on<SendResetLinkSubmitted>((event, emit) async {
      if (state.status == ForgotPasswordStatus.submitting) return;

      final email = state.email.trim();

      if (email.isEmpty || !_emailRegExp.hasMatch(email)) {
        emit(
          state.copyWith(
            emailError: 'Please enter a valid email address.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ForgotPasswordStatus.submitting,
          clearEmailError: true,
        ),
      );

      try {
        await _authRepository.forgotPassword(email);
        _startCountdown();
        emit(state.copyWith(status: ForgotPasswordStatus.success));
      } catch (e) {
        emit(
          state.copyWith(
            status: ForgotPasswordStatus.failure,
            emailError: messageFromError(e),
          ),
        );
      }
    });

    on<ResendLinkSubmitted>((event, emit) async {
      if (!state.canResend) return;

      final email = state.email.trim();

      if (email.isEmpty || !_emailRegExp.hasMatch(email)) {
        emit(
          state.copyWith(
            emailError: 'Please enter a valid email address.',
          ),
        );
        return;
      }

      _startCountdown();

      try {
        await _authRepository.forgotPassword(email);
      } catch (e) {
        emit(state.copyWith(emailError: messageFromError(e)));
      }
    });
  }

  void _startCountdown() {
    _timerSubscription?.cancel();

    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (x) => 29 - x,
    ).take(30).listen((duration) {
      add(
        ResendTimerTicked(duration),
      );
    });
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
