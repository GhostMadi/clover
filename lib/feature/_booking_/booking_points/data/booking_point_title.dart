import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';

/// Имя точки только из локального кэша — без GET `booking_points`.
Future<String?> resolveBookingPointNameCached(String pointId) async {
  final id = pointId.trim();
  if (id.isEmpty) return null;

  final uid = sl<AppSession>().userId;
  if (uid == null || uid.isEmpty) return null;

  final points = await sl<BookingLocalCache>().readMyPoints(uid);
  if (points == null) return null;
  for (final point in points) {
    if (point.id == id) {
      final name = point.name.trim();
      return name.isEmpty ? null : name;
    }
  }
  return null;
}
