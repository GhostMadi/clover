import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum AttendanceLocationResult {
  ok,
  permissionDenied,
  serviceDisabled,
  unavailable,
}

class AttendanceDeviceLocation {
  const AttendanceDeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Device GPS for attendance punch (independent of map widget).
abstract final class AttendanceLocation {
  static Future<(AttendanceLocationResult, AttendanceDeviceLocation?)> current() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return (AttendanceLocationResult.serviceDisabled, null);

    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      return (AttendanceLocationResult.permissionDenied, null);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (
        AttendanceLocationResult.ok,
        AttendanceDeviceLocation(latitude: pos.latitude, longitude: pos.longitude),
      );
    } catch (_) {
      return (AttendanceLocationResult.unavailable, null);
    }
  }

  /// Distance in meters (haversine).
  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }

  static bool inGeofence({
    required double deviceLat,
    required double deviceLng,
    required double centerLat,
    required double centerLng,
    required int radiusM,
  }) {
    return distanceMeters(
          lat1: deviceLat,
          lng1: deviceLng,
          lat2: centerLat,
          lng2: centerLng,
        ) <=
        radiusM;
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
