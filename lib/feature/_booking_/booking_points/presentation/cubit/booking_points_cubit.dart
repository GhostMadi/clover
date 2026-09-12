import 'package:clover/feature/_booking_/booking_points/data/booking_points_prefs.dart';
import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingPointsCubit extends Cubit<BookingPointsState> {
  BookingPointsCubit(this._repository, this._prefs) : super(const BookingPointsState.initial());

  final BookingPointsRepository _repository;
  final BookingPointsPrefs _prefs;

  Future<void> load() async {
    if (isClosed) return;
    emit(const BookingPointsState.loading());
    try {
      final points = await _repository.listMyPoints();
      final lastId = await _prefs.readLastPointId();
      if (isClosed) return;
      emit(BookingPointsState.loaded(points: points, lastPointId: lastId));
    } catch (e) {
      if (isClosed) return;
      emit(BookingPointsState.error('$e'));
    }
  }

  Future<BookingPoint?> create(String name) async {
    try {
      final point = await _repository.createPoint(name);
      await _prefs.writeLastPointId(point.id);
      await load();
      return point;
    } catch (_) {
      return null;
    }
  }

  Future<void> remember(String pointId) => _prefs.writeLastPointId(pointId);
}

sealed class BookingPointsState {
  const BookingPointsState();

  const factory BookingPointsState.initial() = BookingPointsInitial;
  const factory BookingPointsState.loading() = BookingPointsLoading;
  const factory BookingPointsState.loaded({
    required List<BookingPoint> points,
    String? lastPointId,
  }) = BookingPointsLoaded;
  const factory BookingPointsState.error(String message) = BookingPointsError;
}

final class BookingPointsInitial extends BookingPointsState {
  const BookingPointsInitial();
}

final class BookingPointsLoading extends BookingPointsState {
  const BookingPointsLoading();
}

final class BookingPointsLoaded extends BookingPointsState {
  const BookingPointsLoaded({required this.points, this.lastPointId});

  final List<BookingPoint> points;
  final String? lastPointId;
}

final class BookingPointsError extends BookingPointsState {
  const BookingPointsError(this.message);

  final String message;
}
