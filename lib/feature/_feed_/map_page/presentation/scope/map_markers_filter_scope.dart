import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:flutter/material.dart';

class MapMarkersFilterScope extends InheritedWidget {
  const MapMarkersFilterScope({
    super.key,
    required this.filter,
    required super.child,
  });

  final EventsFilter filter;

  static EventsFilter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MapMarkersFilterScope>();
    return scope?.filter ?? EventsFilter.defaults;
  }

  @override
  bool updateShouldNotify(MapMarkersFilterScope oldWidget) => filter != oldWidget.filter;
}
