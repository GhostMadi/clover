import 'package:supabase_flutter/supabase_flutter.dart';

enum AttendanceErrorCode {
  notAuthenticated,
  invalidArguments,
  forbidden,
  notFound,
  notActiveMember,
  needsAck,
  outsideGeofence,
  locationRequired,
  invalidPunch,
  punchTypeInvalid,
  unknown,
}

class AttendanceException implements Exception {
  const AttendanceException(this.code, [this.message]);

  final AttendanceErrorCode code;
  final String? message;

  @override
  String toString() => message ?? code.name;

  static AttendanceException from(Object error) {
    if (error is AttendanceException) return error;
    if (error is PostgrestException) {
      return AttendanceException(_codeFromPostgres(error), error.message);
    }
    return AttendanceException(AttendanceErrorCode.unknown, '$error');
  }

  static AttendanceErrorCode _codeFromPostgres(PostgrestException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('needs_ack')) return AttendanceErrorCode.needsAck;
    if (msg.contains('outside_geofence')) return AttendanceErrorCode.outsideGeofence;
    if (msg.contains('location_required')) return AttendanceErrorCode.locationRequired;
    if (msg.contains('not_active_member') || msg.contains('already_member') || msg.contains('invalid_status')) {
      return AttendanceErrorCode.notActiveMember;
    }
    if (msg.contains('invalid_punch')) return AttendanceErrorCode.invalidPunch;
    if (msg.contains('punch_type')) return AttendanceErrorCode.punchTypeInvalid;
    return switch (error.code) {
      'P0003' => AttendanceErrorCode.notAuthenticated,
      'P0101' => AttendanceErrorCode.invalidArguments,
      'P0102' => AttendanceErrorCode.forbidden,
      'P0103' => AttendanceErrorCode.notFound,
      'P0104' => AttendanceErrorCode.notActiveMember,
      'P0105' => AttendanceErrorCode.needsAck,
      'P0106' => AttendanceErrorCode.outsideGeofence,
      'P0107' => AttendanceErrorCode.locationRequired,
      'P0108' => AttendanceErrorCode.invalidPunch,
      'P0109' => AttendanceErrorCode.punchTypeInvalid,
      _ => AttendanceErrorCode.unknown,
    };
  }

  String get userMessage => switch (code) {
        AttendanceErrorCode.notAuthenticated => 'Войдите в аккаунт',
        AttendanceErrorCode.invalidArguments => 'Некорректные данные',
        AttendanceErrorCode.forbidden => 'Недостаточно прав',
        AttendanceErrorCode.notFound => 'Не найдено',
        AttendanceErrorCode.notActiveMember => 'Нет активного членства',
        AttendanceErrorCode.needsAck => 'Примите правила компании в чате',
        AttendanceErrorCode.outsideGeofence => 'Вы вне геозоны',
        AttendanceErrorCode.locationRequired => 'Нужна геолокация',
        AttendanceErrorCode.invalidPunch => 'Отметка недоступна в этом состоянии смены',
        AttendanceErrorCode.punchTypeInvalid => 'Неверный тип отметки',
        AttendanceErrorCode.unknown => message ?? 'Не удалось выполнить операцию',
      };
}
