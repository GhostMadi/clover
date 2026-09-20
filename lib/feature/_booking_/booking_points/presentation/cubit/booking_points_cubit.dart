import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_points_prefs.dart';
import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingPointsCubit extends Cubit<BookingPointsState> {
  BookingPointsCubit(this._repository, this._prefs, this._cache, this._session)
      : super(const BookingPointsState.initial());

  final BookingPointsRepository _repository;
  final BookingPointsPrefs _prefs;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load() async {
    if (isClosed) return;

    final uid = _session.userId;
    final already = state is BookingPointsLoaded ? state as BookingPointsLoaded : null;

    if (already != null) {
      await _syncRemote(keepRefreshing: true);
      return;
    }

    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readMyPoints(uid);
      final lastId = await _prefs.readLastPointId();
      if (isClosed) return;
      if (cached != null) {
        emit(
          BookingPointsState.loaded(
            points: cached,
            lastPointId: lastId,
            isFromCache: true,
          ),
        );
      } else {
        emit(const BookingPointsState.loading());
      }
    } else {
      emit(const BookingPointsState.loading());
    }

    await _syncRemote();
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final loaded = state is BookingPointsLoaded ? state as BookingPointsLoaded : null;
    if (loaded == null) {
      await load();
      return;
    }
    await _syncRemote(keepRefreshing: true);
  }

  Future<void> _syncRemote({bool keepRefreshing = false}) async {
    final prev = state is BookingPointsLoaded ? state as BookingPointsLoaded : null;
    if (keepRefreshing && prev != null && !isClosed) {
      emit(prev.copyWith(isRefreshing: true));
    }

    try {
      final points = await _repository.listMyPoints();
      final lastId = await _prefs.readLastPointId();
      if (isClosed) return;
      emit(
        BookingPointsState.loaded(
          points: points,
          lastPointId: lastId,
          isFromCache: false,
          isRefreshing: false,
        ),
      );

      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeMyPoints(uid, points);
      }
    } catch (e) {
      if (isClosed) return;
      if (prev != null) {
        emit(prev.copyWith(isRefreshing: false));
        return;
      }
      emit(BookingPointsState.error('$e'));
    }
  }

  Future<BookingPoint?> create(String name) async {
    try {
      final point = await _repository.createPoint(name);
      await _prefs.writeLastPointId(point.id);

      final prev = state is BookingPointsLoaded ? state as BookingPointsLoaded : null;
      if (prev != null && !isClosed) {
        final next = [point, ...prev.points.where((p) => p.id != point.id)];
        emit(
          BookingPointsState.loaded(
            points: next,
            lastPointId: point.id,
            isFromCache: false,
          ),
        );
        final uid = _session.userId;
        if (uid != null && uid.isNotEmpty) {
          await _cache.writeMyPoints(uid, next);
        }
      } else {
        await load();
      }
      return point;
    } catch (_) {
      return null;
    }
  }

  Future<void> remember(String pointId) => _prefs.writeLastPointId(pointId);

  /// Показать уже известный список (свитчер) до фонового sync.
  void emitSeeded(List<BookingPoint> points) {
    if (isClosed || points.isEmpty) return;
    emit(
      BookingPointsState.loaded(
        points: points,
        isFromCache: true,
      ),
    );
  }

  /// Имя точки: кэш списка → сеть `getPoint`. Без UI.
  Future<String?> resolvePointName(String pointId) async {
    final id = pointId.trim();
    if (id.isEmpty) return null;

    final loaded = state is BookingPointsLoaded ? state as BookingPointsLoaded : null;
    if (loaded != null) {
      for (final p in loaded.points) {
        if (p.id == id) return p.name;
      }
    }

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readMyPoints(uid);
      if (cached != null) {
        for (final p in cached) {
          if (p.id == id) return p.name;
        }
      }
    }

    try {
      final point = await _repository.getPoint(id);
      return point?.name;
    } catch (_) {
      return null;
    }
  }
}

sealed class BookingPointsState {
  const BookingPointsState();

  const factory BookingPointsState.initial() = BookingPointsInitial;
  const factory BookingPointsState.loading() = BookingPointsLoading;
  const factory BookingPointsState.loaded({
    required List<BookingPoint> points,
    String? lastPointId,
    bool isFromCache,
    bool isRefreshing,
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
  const BookingPointsLoaded({
    required this.points,
    this.lastPointId,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  final List<BookingPoint> points;
  final String? lastPointId;
  final bool isFromCache;
  final bool isRefreshing;

  BookingPointsLoaded copyWith({
    List<BookingPoint>? points,
    String? lastPointId,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return BookingPointsLoaded(
      points: points ?? this.points,
      lastPointId: lastPointId ?? this.lastPointId,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class BookingPointsError extends BookingPointsState {
  const BookingPointsError(this.message);

  final String message;
}
