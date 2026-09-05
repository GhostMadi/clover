enum AttendancePunchBlockReason {
  needsAck,
  outsideGeofence,
  gpsDisabled,
  noPrimaryPunchType,
}

extension AttendancePunchBlockReasonX on AttendancePunchBlockReason {
  String get titleRu => switch (this) {
        AttendancePunchBlockReason.needsAck => 'Нужно принять правила',
        AttendancePunchBlockReason.outsideGeofence => 'Вы вне зоны',
        AttendancePunchBlockReason.gpsDisabled => 'Геолокация выключена',
        AttendancePunchBlockReason.noPrimaryPunchType => 'Отметки не настроены',
      };

  String get detailRu => switch (this) {
        AttendancePunchBlockReason.needsAck =>
          'Админ обновил правила компании. Откройте чат и нажмите «Понятно, принимаю».',
        AttendancePunchBlockReason.outsideGeofence =>
          'Отметка возможна только внутри геозоны. Подойдите к точке компании.',
        AttendancePunchBlockReason.gpsDisabled =>
          'Разрешите геолокацию для Clover в настройках телефона.',
        AttendancePunchBlockReason.noPrimaryPunchType =>
          'Админ не включил «Пришёл» и «Ушёл». Используйте свои отметки, если они есть.',
      };
}
