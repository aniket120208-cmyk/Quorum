import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/meeting_history_item.dart';
import '../models/meeting_result.dart';

enum VideoCallStatus { initial, loading, created, failure }

class VideoCallState {
  final VideoCallStatus status;
  final String? code;
  final String? error;
  final List<MeetingHistoryItem> history;

  const VideoCallState({
    this.status = VideoCallStatus.initial,
    this.code,
    this.error,
    this.history = const [],
  });

  VideoCallState copyWith({
    VideoCallStatus? status,
    String? code,
    String? error,
    List<MeetingHistoryItem>? history,
  }) {
    return VideoCallState(
      status: status ?? this.status,
      code: code ?? this.code,
      error: error,
      history: history ?? this.history,
    );
  }
}

class VideoCallCubit extends Cubit<VideoCallState> {
  VideoCallCubit() : super(const VideoCallState());
  void loadHistory() {}

  Future<void> createMeeting() async {
    emit(state.copyWith(status: VideoCallStatus.loading));
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(
      status: VideoCallStatus.created,
      code: _generateRandomCode(),
    ));
  }

  void recordMeeting(MeetingResult result) {
    if (!result.joined) return;

    final item = MeetingHistoryItem(
      title: result.title,
      code: result.code,
      timestamp: result.joinedAt ?? DateTime.now(),
      duration: result.formattedDuration,
    );

    final others = state.history.where((h) => h.code != result.code);
    emit(state.copyWith(history: [item, ...others]));
  }

  void removeMeeting(MeetingHistoryItem item) {
    emit(state.copyWith(
      history: state.history.where((h) => h != item).toList(),
    ));
  }

  void restoreMeeting(MeetingHistoryItem item, int index) {
    final list = [...state.history];
    list.insert(index.clamp(0, list.length), item);
    emit(state.copyWith(history: list));
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    String chunk(int length) =>
        List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    return '${chunk(3)}-${chunk(4)}-${chunk(3)}';
  }
}