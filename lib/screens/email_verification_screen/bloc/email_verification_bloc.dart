import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'email_verification_event.dart';
import 'email_verification_state.dart';

class EmailVerificationBloc
    extends Bloc<EmailVerificationEvent, EmailVerificationState> {
  StreamSubscription<int>? _timerSubscription;

  EmailVerificationBloc() : super(const EmailVerificationState()) {
    _startCountdown();

    on<OtpDigitChanged>((event, emit) {
      final updatedDigits = List<String>.from(state.otpDigits);
      updatedDigits[event.index] = event.digit;

      emit(state.copyWith(
        otpDigits: updatedDigits,
        status: OtpStatus.initial,
        clearMessage: true,
      ));
    });

    on<ResendOtpTimerTicked>((event, emit) {
      emit(state.copyWith(resendCountdown: event.duration));
    });

    on<ResendOtpSubmitted>((event, emit) async {
      if (!state.canResend) return;

      _startCountdown();
      emit(state.copyWith(
        status: OtpStatus.initial,
        clearMessage: true,
      ));
    });

    on<VerifyOtpSubmitted>((event, emit) async {
      if (!state.isFilled) {
        emit(state.copyWith(
          status: OtpStatus.failure,
          message: 'Invalid otp, try again!',
        ));
        return;
      }

      emit(state.copyWith(
        status: OtpStatus.submitting,
        clearMessage: true,
      ));

      await Future.delayed(const Duration(seconds: 1));

      if (state.fullOtp == '123456') {
        emit(state.copyWith(
          status: OtpStatus.success,
          message: 'Successfully verified!',
        ));
      } else {
        emit(state.copyWith(
          status: OtpStatus.failure,
          message: 'Invalid otp, try again!',
        ));
      }
    });
  }

  void _startCountdown() {
    _timerSubscription?.cancel();
    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (x) => 14 - x,
    ).take(15).listen((duration) {
      add(ResendOtpTimerTicked(duration));
    });
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}