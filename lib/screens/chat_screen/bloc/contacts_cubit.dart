import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quorum/models/chat_models.dart';
import 'package:quorum/repositories/chat_repository.dart';

enum ContactsStatus { loading, ready, permissionDenied, failure }

class ContactsState {
  const ContactsState({
    this.status = ContactsStatus.loading,
    this.phoneContacts = const [],
    this.searchResults = const [],
    this.query = '',
    this.searching = false,
    this.error,
  });

  final ContactsStatus status;
  final List<ChatUser> phoneContacts;
  final List<ChatUser> searchResults;
  final String query;
  final bool searching;
  final String? error;

  ContactsState copyWith({
    ContactsStatus? status,
    List<ChatUser>? phoneContacts,
    List<ChatUser>? searchResults,
    String? query,
    bool? searching,
    String? error,
  }) {
    return ContactsState(
      status: status ?? this.status,
      phoneContacts: phoneContacts ?? this.phoneContacts,
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
      searching: searching ?? this.searching,
      error: error,
    );
  }
}

class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit(this._repo) : super(const ContactsState());
  final ChatRepository _repo;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      final users = await _repo.matchPhoneContacts();
      if (isClosed) return;
      if (users == null) {
        emit(state.copyWith(status: ContactsStatus.permissionDenied));
        return;
      }
      final sorted = [...users]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(state.copyWith(status: ContactsStatus.ready, phoneContacts: sorted));
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: ContactsStatus.failure, error: '$e'));
      }
    }
  }

  void onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    emit(state.copyWith(query: q, searching: q.length >= 2));
    if (q.length < 2) {
      emit(state.copyWith(searchResults: const [], searching: false));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _repo.searchUsers(q);
        if (!isClosed && state.query == q) {
          emit(state.copyWith(searchResults: results, searching: false));
        }
      } catch (_) {
        if (!isClosed && state.query == q) {
          emit(state.copyWith(searchResults: const [], searching: false));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}