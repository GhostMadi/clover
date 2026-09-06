import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingStaffSearchCubit extends Cubit<BookingStaffSearchState> {
  BookingStaffSearchCubit(this._repository) : super(const BookingStaffSearchState());

  final BookingStaffRepository _repository;
  Set<String> _excludeProfileIds = const {};

  void configure({Set<String> excludeProfileIds = const {}}) {
    _excludeProfileIds = excludeProfileIds;
  }

  Future<void> search(String query) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final rows = await _repository.searchProfiles(
        query,
        excludeProfileIds: _excludeProfileIds,
      );
      emit(state.copyWith(results: rows, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: '$e', results: const []));
    }
  }
}

class BookingStaffSearchState {
  const BookingStaffSearchState({
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final List<BookingStaffProfile> results;
  final bool loading;
  final String? error;

  BookingStaffSearchState copyWith({
    List<BookingStaffProfile>? results,
    bool? loading,
    String? error,
  }) {
    return BookingStaffSearchState(
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
