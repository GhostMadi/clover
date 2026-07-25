/// Запись в истории бонусов у конкретного аккаунта.
class BonusHistoryEntry {
  const BonusHistoryEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.occurredAt,
    this.isCredit = true,
    this.source,
    this.sourceId,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime occurredAt;
  final bool isCredit;

  /// Источник операции: booking_service, booking_payment, manual, promo, welcome.
  final String? source;
  final String? sourceId;

  String get amountLabel {
    final prefix = isCredit ? '+' : '−';
    return '$prefix$amount';
  }
}
