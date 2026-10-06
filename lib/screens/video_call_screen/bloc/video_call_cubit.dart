import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_client.dart';

enum VideoCallStatus { initial, loading, created, failure }

class VideoCallState {
  final VideoCallStatus status;
  final String? code;
  final String? error;

  const VideoCallState({
    this.status = VideoCallStatus.initial,
    this.code,
    this.error,
  });

  VideoCallState copyWith({
    VideoCallStatus? status,
    String? code,
    String? error,
  }) {
    return VideoCallState(
      status: status ?? this.status,
      code: code ?? this.code,
      error: error,
    );
  }
}

class VideoCallCubit extends Cubit<VideoCallState> {
  final ApiClient? apiClient;

  VideoCallCubit({this.apiClient}) : super(const VideoCallState());

  Future<void> createMeeting() async {
    emit(state.copyWith(status: VideoCallStatus.loading));
    await Future.delayed(const Duration(milliseconds: 500));
    
    final generatedCode = _generateRandomCode();
    emit(state.copyWith(
      status: VideoCallStatus.created,
      code: generatedCode,
    ));
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    String chunk(int length) =>
        List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    return '${chunk(3)}-${chunk(4)}-${chunk(3)}';
  }
}