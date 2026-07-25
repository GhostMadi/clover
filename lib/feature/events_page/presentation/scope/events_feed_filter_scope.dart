import 'package:clover/feature/events_page/data/models/events_filter.dart';
import 'package:flutter/material.dart';

class EventsFeedFilterScope extends InheritedWidget {
  const EventsFeedFilterScope({
    super.key,
    required this.filter,
    required super.child,
  });

  final EventsFilter filter;

  static EventsFilter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EventsFeedFilterScope>();
    return scope?.filter ?? EventsFilter.defaults;
  }

  @override
  bool updateShouldNotify(EventsFeedFilterScope oldWidget) => filter != oldWidget.filter;
}
