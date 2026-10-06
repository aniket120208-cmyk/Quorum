import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/api/api_client.dart';
import 'package:quorum/api/api_exception.dart';

enum HomeStatus { idle, loading, created, failure }

class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.idle, this.code, this.error});
  final HomeStatus status;
  final String? code;
  final String? error;

  @override
  List<Object?> get props => [status, code, error];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const HomeState());

  final ApiClient _apiClient;

  Future<void> createMeeting({Map<String, dynamic>? body}) async {
    emit(const HomeState(status: HomeStatus.loading));
    try {
      final data = await _apiClient.createMeeting(body: body);
      emit(HomeState(
        status: HomeStatus.created,
        code: data['code']?.toString(),
      ));
    } catch (e) {
      emit(HomeState(
        status: HomeStatus.failure,
        error: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}