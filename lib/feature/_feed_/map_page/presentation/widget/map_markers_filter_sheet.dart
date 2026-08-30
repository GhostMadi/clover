import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/events_page/presentation/widget/events_filter_sheet.dart';
import 'package:flutter/material.dart';

abstract final class MapMarkersFilterSheet {
  static Future<EventsFilter?> show(BuildContext context, {required EventsFilter initial}) {
    return EventsFilterSheet.show(context, initial: initial, mode: EventsFilterSheetMode.map);
  }
}
