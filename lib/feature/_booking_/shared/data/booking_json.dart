abstract final class BookingJson {
  static String? asString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? fallback;
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? asIsoString(dynamic value) {
    final dt = asDateTime(value);
    return dt?.toIso8601String();
  }

  static (int hour, int minute) parseTime(dynamic value) {
    final raw = asString(value);
    if (raw == null) return (9, 0);
    final parts = raw.split(':');
    if (parts.length < 2) return (9, 0);
    return (int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
  }

  static List<int> asIntList(dynamic value) {
    if (value is! List) return const [];
    return [for (final item in value) asInt(item)];
  }
}
