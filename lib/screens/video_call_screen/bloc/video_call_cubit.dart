import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_client.dart';
import 'package:quorum/api/api_exception.dart';

enum VideoCallStatus { idle, loading, created, failure }

class VideoCallState extends Equatable {
  const VideoCallState({
    this.status = VideoCallStatus.idle,
    this.code,
    this.error,
  });
  final VideoCallStatus status;
  final String? code;
  final String? error;

  @override
  List<Object?> get props => [status, code, error];
}

class VideoCallCubit extends Cubit<VideoCallState> {
  VideoCallCubit({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const VideoCallState());

  final ApiClient _apiClient;

  Future<void> createMeeting({Map<String, dynamic>? body}) async {
    emit(const VideoCallState(status: VideoCallStatus.loading));
    try {
      final data = await _apiClient.createMeeting(body: body);
      emit(VideoCallState(
        status: VideoCallStatus.created,
        code: data['code']?.toString(),
      ));
    } catch (e) {
      emit(VideoCallState(
        status: VideoCallStatus.failure,
        error: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}