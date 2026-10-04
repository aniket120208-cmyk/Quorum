import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_exception.dart';
import 'package:quorum/repositories/auth_repository.dart';
import 'email_verification_event.dart';
import 'email_verification_state.dart';

class EmailVerificationBloc
    extends Bloc<EmailVerificationEvent, EmailVerificationState> {
  EmailVerificationBloc({
    required AuthRepository authRepository,
    required String email,
  })  : _authRepository = authRepository,
        _email = email,
        super(const EmailVerificationState()) {
    on<OtpDigitChanged>(_onOtpDigitChanged);
    on<ResendOtpTimerTicked>(_onResendOtpTimerTicked);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<ResendOtpSubmitted>(_onResendOtpSubmitted);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);

    add(SendOtpRequested());
  }

  final AuthRepository _authRepository;
  final String _email;
  StreamSubscription<int>? _timerSubscription;

  void _onOtpDigitChanged(
    OtpDigitChanged event,
    Emitter<EmailVerificationState> emit,
  ) {
    final updatedDigits = List<String>.from(state.otpDigits);
    updatedDigits[event.index] = event.digit;

    emit(
      state.copyWith(
        otpDigits: updatedDigits,
        status: OtpStatus.initial,
        clearMessage: true,
      ),
    );
  }

  void _onResendOtpTimerTicked(
    ResendOtpTimerTicked event,
    Emitter<EmailVerificationState> emit,
  ) {
    emit(
      state.copyWith(
        resendCountdown: event.duration,
      ),
    );
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<EmailVerificationState> emit,
  ) async {
    await _sendOtp(emit);
  }

  Future<void> _onResendOtpSubmitted(
    ResendOtpSubmitted event,
    Emitter<EmailVerificationState> emit,
  ) async {
    if (!state.canResend) return;

    await _sendOtp(emit);
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<EmailVerificationState> emit,
  ) async {
    if (state.status == OtpStatus.submitting) return;

    if (!state.isFilled) {
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          message: 'Invalid OTP, try again!',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: OtpStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _authRepository.verifyEmail(email: _email, otp: state.fullOtp);

      emit(
        state.copyWith(
          status: OtpStatus.success,
          message: 'Successfully verified!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          message: messageFromError(e),
        ),
      );
    }
  }

  Future<void> _sendOtp(
    Emitter<EmailVerificationState> emit,
  ) async {
    _startCountdown();

    emit(
      state.copyWith(
        status: OtpStatus.initial,
        clearMessage: true,
      ),
    );

    try {
      await _authRepository.sendVerificationOtp(_email);
    } catch (e) {
      await _timerSubscription?.cancel();

      emit(
        state.copyWith(
          resendCountdown: 0,
          status: OtpStatus.initial,
          message: messageFromError(e),
        ),
      );
    }
  }

  void _startCountdown() {
    _timerSubscription?.cancel();

    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (x) => 29 - x,
    ).take(30).listen(
      (duration) {
        add(ResendOtpTimerTicked(duration));
      },
    );
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}