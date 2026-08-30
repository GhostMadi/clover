import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_markers_pagination.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/data/repository/map_markers_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class MapMarkersCubit extends Cubit<MapMarkersState> {
  MapMarkersCubit(this._repository) : super(const MapMarkersState.initial());

  final MapMarkersRepository _repository;

  int _loadGeneration = 0;
  int _currentPage = 0;
  AppMapViewport? _viewport;
  EventsFilter? _filter;

  Future<void> load({
    required AppMapViewport viewport,
    required EventsFilter filter,
    bool resetPage = false,
  }) async {
    if (resetPage) _currentPage = 0;
    _viewport = viewport;
    _filter = filter;
    await _fetchPage(refreshTotal: true);
  }

  Future<void> nextPage() async {
    if (!state.canGoNext || state.isLoading) return;
    _currentPage++;
    await _fetchPage(refreshTotal: false);
  }

  Future<void> previousPage() async {
    if (!state.canGoPrevious || state.isLoading) return;
    _currentPage--;
    await _fetchPage(refreshTotal: false);
  }

  Future<void> _fetchPage({required bool refreshTotal}) async {
    final viewport = _viewport;
    final filter = _filter;
    if (viewport == null || filter == null) return;

    final generation = ++_loadGeneration;
    final previousMarkers = state.mapMarkers;

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        mapMarkers: previousMarkers,
      ),
    );

    try {
      final offset = _currentPage * MapMarkersPagination.pageSize;
      final pageFuture = _repository.fetchPage(
        center: viewport.center,
        zoom: viewport.zoom,
        filter: filter,
        offset: offset,
        limit: MapMarkersPagination.pageSize,
      );
      final countFuture = refreshTotal
          ? _repository.countMarkers(center: viewport.center, zoom: viewport.zoom, filter: filter)
          : Future.value(state.totalCount);

      final page = await pageFuture;
      var total = await countFuture;

      if (isClosed || generation != _loadGeneration) return;

      final maxPage = total == 0 ? 0 : ((total - 1) / MapMarkersPagination.pageSize).floor();
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }

      final effectiveOffset = _currentPage * MapMarkersPagination.pageSize;
      final effectivePage = effectiveOffset == offset
          ? page
          : await _repository.fetchPage(
              center: viewport.center,
              zoom: viewport.zoom,
              filter: filter,
              offset: effectiveOffset,
              limit: MapMarkersPagination.pageSize,
            );

      if (isClosed || generation != _loadGeneration) return;

      emit(
        MapMarkersState.loaded(
          markers: effectivePage.items,
          mapMarkers: [
            for (final item in effectivePage.items)
              AppMapMarker(
                id: item.id,
                point: item.point,
                emoji: item.textEmoji,
              ),
          ],
          currentPage: _currentPage,
          pageSize: MapMarkersPagination.pageSize,
          totalCount: total,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
          mapMarkers: previousMarkers,
        ),
      );
    }
  }
}

class MapMarkersState {
  const MapMarkersState._({
    required this.isLoading,
    this.markers = const [],
    this.mapMarkers = const [],
    this.currentPage = 0,
    this.pageSize = MapMarkersPagination.pageSize,
    this.totalCount = 0,
    this.errorMessage,
  });

  const MapMarkersState.initial() : this._(isLoading: false);

  const MapMarkersState.loaded({
    required List<MapMarkerItem> markers,
    required List<AppMapMarker> mapMarkers,
    required int currentPage,
    required int pageSize,
    required int totalCount,
  }) : this._(
    isLoading: false,
    markers: markers,
    mapMarkers: mapMarkers,
    currentPage: currentPage,
    pageSize: pageSize,
    totalCount: totalCount,
  );

  final bool isLoading;
  final List<MapMarkerItem> markers;
  final List<AppMapMarker> mapMarkers;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final String? errorMessage;

  int get rangeStart => totalCount == 0 ? 0 : currentPage * pageSize + 1;

  int get rangeEnd {
    if (totalCount == 0) return 0;
    final end = (currentPage + 1) * pageSize;
    return end > totalCount ? totalCount : end;
  }

  bool get canGoPrevious => currentPage > 0 && !isLoading;

  bool get canGoNext => rangeEnd < totalCount && !isLoading;

  MapMarkersState copyWith({
    bool? isLoading,
    List<MapMarkerItem>? markers,
    List<AppMapMarker>? mapMarkers,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
  }) {
    return MapMarkersState._(
      isLoading: isLoading ?? this.isLoading,
      markers: markers ?? this.markers,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage,
    );
  }
}
