import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_points_prefs.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';

/// Last point if set, otherwise host default (creates «Основная» when needed).
Future<String> resolveBookingPointIdForNav() async {
  final last = await sl<BookingPointsPrefs>().readLastPointId();
  if (last != null && last.isNotEmpty) return last;
  return sl<BookingPointsRepository>().ensureDefaultPointId();
}
