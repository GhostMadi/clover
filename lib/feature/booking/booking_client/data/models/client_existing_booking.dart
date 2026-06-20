/// Запись клиента у другого аккаунта — учитывается при выборе времени.
class ClientExistingBooking {
  const ClientExistingBooking({
    required this.id,
    required this.hostName,
    required this.startsAt,
    required this.durationMinutes,
    this.bufferAfterMinutes = 0,
  });

  final String id;
  final String hostName;
  final DateTime startsAt;
  final int durationMinutes;
  final int bufferAfterMinutes;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes + bufferAfterMinutes));

  String get conflictLabel {
    final from = _formatTime(startsAt);
    final to = _formatTime(endsAt);
    return '$hostName · $from — $to';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
