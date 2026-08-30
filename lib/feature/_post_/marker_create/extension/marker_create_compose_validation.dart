import 'package:clover/feature/marker_create/model/marker_create_compose_result.dart';

extension MarkerCreateComposeResultValidation on MarkerCreateComposeResult {
  bool get isValid {
    if (media.isEmpty) return false;
    if (textEmoji.trim().isEmpty) return false;
    if (location == null) return false;
    if (!_hasCoordinates) return false;
    if (eventPeriod == null) return false;

    final duration = eventPeriod!.duration;
    if (duration.inMinutes <= 0) return false;
    if (duration > const Duration(hours: 24)) return false;

    return true;
  }

  bool get _hasCoordinates {
    final lat = location!.latitude;
    final lng = location!.longitude;
    return lat != null && lng != null;
  }
}
