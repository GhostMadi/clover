import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';

/// Оценка движения бонусов при записи (факт — на бэке при completed).
abstract final class ClientBookingBonusPreview {
  static int maxSpendAmount({
    required double price,
    required int bonusPayPercent,
  }) {
    if (bonusPayPercent <= 0 || price <= 0) return 0;
    return (price * bonusPayPercent / 100).floor();
  }

  static int expectedSpend({
    required BookingService service,
    required int balance,
    required bool useBonuses,
  }) {
    if (!useBonuses || service.bonusPayPercent <= 0) return 0;
    final cap = maxSpendAmount(price: service.price, bonusPayPercent: service.bonusPayPercent);
    if (cap <= 0) return 0;
    return balance < cap ? balance : cap;
  }

  static int expectedEarn(BookingService service) {
    return service.bonusEarnAmount < 0 ? 0 : service.bonusEarnAmount;
  }

  static bool hasBonusFlow(BookingService service) {
    return service.bonusPayPercent > 0 || service.bonusEarnAmount > 0;
  }
}
