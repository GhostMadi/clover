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
  notOnDuty,
  network,
  unknown,
}

class AttendanceException implements Exception {
  const AttendanceException(this.code, [this.message]);

  final AttendanceErrorCode code;
  final String? message;

  @override
  String toString() => message ?? code.name;

  /// Сетевой сбой / таймаут — кандидат в outbox.
  bool get isRetriableNetwork {
    if (code == AttendanceErrorCode.network) return true;
    final m = (message ?? '').toLowerCase();
    return m.contains('socket') ||
        m.contains('network') ||
        m.contains('timeout') ||
        m.contains('failed host lookup') ||
        m.contains('connection') ||
        m.contains('offline');
  }

  static AttendanceException from(Object error) {
    if (error is AttendanceException) return error;
    if (error is PostgrestException) {
      return AttendanceException(_codeFromPostgres(error), error.message);
    }
    final text = '$error';
    final lower = text.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception')) {
      return AttendanceException(AttendanceErrorCode.network, text);
    }
    return AttendanceException(AttendanceErrorCode.unknown, text);
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
    if (msg.contains('not_on_duty')) return AttendanceErrorCode.notOnDuty;
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
      'P0110' => AttendanceErrorCode.notOnDuty,
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
        AttendanceErrorCode.notOnDuty => 'Сегодня не ваше дежурство — отметка недоступна',
        AttendanceErrorCode.network => 'Нет сети — действие в очереди синхронизации',
        AttendanceErrorCode.unknown => message ?? 'Не удалось выполнить операцию',
      };
}
