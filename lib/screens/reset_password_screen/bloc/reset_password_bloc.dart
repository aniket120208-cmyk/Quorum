import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'package:quorum/utils/validators.dart';

import 'reset_password_event.dart';
import 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final AuthRepository _authRepository;
  final String _email;
  StreamSubscription<int>? _timerSubscription;

  ResetPasswordBloc({
    required AuthRepository authRepository,
    required String email,
  })  : _authRepository = authRepository,
        _email = email,
        super(const ResetPasswordState()) {
    _startCountdown();

    on<ResetOtpChanged>((event, emit) {
      emit(
        state.copyWith(
          otp: event.otp,
          status: ResetPasswordStatus.initial,
          clearMessage: true,
        ),
      );
    });

    on<ResetNewPasswordChanged>((event, emit) {
      final password = event.password;

      final passwordFormatError = _validatePassword(password);

      final isMismatch = state.confirmPassword.isNotEmpty &&
          password != state.confirmPassword;

      emit(
        state.copyWith(
          newPassword: password,
          passwordFormatError: passwordFormatError,
          passwordError: isMismatch
              ? 'The password does not match.'
              : null,
          clearPasswordError: !isMismatch,
          clearMessage: true,
        ),
      );
    });

    on<ResetConfirmPasswordChanged>((event, emit) {
      final isMismatch = event.password != state.newPassword;

      emit(
        state.copyWith(
          confirmPassword: event.password,
          passwordError: isMismatch
              ? 'The password does not match.'
              : null,
          clearPasswordError: !isMismatch,
          clearMessage: true,
        ),
      );
    });

    on<ResetToggleNewPasswordVisibility>((event, emit) {
      emit(
        state.copyWith(
          obscureNewPassword: !state.obscureNewPassword,
        ),
      );
    });

    on<ResetToggleConfirmPasswordVisibility>((event, emit) {
      emit(
        state.copyWith(
          obscureConfirmPassword:
              !state.obscureConfirmPassword,
        ),
      );
    });

    on<ResetTimerTicked>((event, emit) {
      emit(
        state.copyWith(
          resendCountdown: event.duration,
        ),
      );
    });

    on<ResetOtpResendRequested>((event, emit) async {
      if (!state.canResend) return;

      _startCountdown();

      emit(
        state.copyWith(
          clearMessage: true,
        ),
      );

      try {
        await _authRepository.forgotPassword(_email);
      } catch (e) {
        _timerSubscription?.cancel();

        emit(
          state.copyWith(
            resendCountdown: 0,
            message: messageFromError(e),
          ),
        );
      }
    });

    on<ResetPasswordSubmitted>((event, emit) async {
      if (state.status == ResetPasswordStatus.submitting) return;

      if (state.otp.length != 6) {
        emit(
          state.copyWith(
            status: ResetPasswordStatus.failure,
            message: 'Enter the 6-digit code from your email.',
          ),
        );
        return;
      }

      if (state.newPassword.isEmpty) {
        emit(
          state.copyWith(
            passwordFormatError: 'Please enter a new password.',
            clearPasswordError: true,
          ),
        );
        return;
      }

      final passwordFormatError = _validatePassword(state.newPassword);

      if (passwordFormatError != null) {
        emit(
          state.copyWith(
            passwordFormatError: passwordFormatError,
            status: ResetPasswordStatus.failure,
          ),
        );
        return;
      }

      if (state.newPassword != state.confirmPassword) {
        emit(
          state.copyWith(
            passwordError: 'The password does not match.',
            status: ResetPasswordStatus.failure,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ResetPasswordStatus.submitting,
          clearPasswordFormatError: true,
          clearPasswordError: true,
          clearMessage: true,
        ),
      );

      try {
        await _authRepository.resetPassword(
          email: _email,
          otp: state.otp,
          newPassword: state.newPassword,
        );

        emit(
          state.copyWith(
            status: ResetPasswordStatus.success,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: ResetPasswordStatus.failure,
            message: messageFromError(e),
          ),
        );
      }
    });
  }

  String? _validatePassword(String password) {
    if (!PasswordRules.hasMinLength(password)) {
      return 'Password must be at least 8 characters long.';
    }

    if (!PasswordRules.hasUppercase(password)) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!PasswordRules.hasLowercase(password)) {
      return 'Password must contain at least one lowercase letter.';
    }

    if (!PasswordRules.hasSpecial(password)) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  void _startCountdown() {
    _timerSubscription?.cancel();

    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (x) => 29 - x,
    ).take(30).listen((duration) {
      add(ResetTimerTicked(duration));
    });
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}