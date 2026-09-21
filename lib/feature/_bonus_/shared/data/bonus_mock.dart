import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';

/// Локальные моки для UI «Мои бонусы» / история.
///
/// Включи [enabled], чтобы смотреть дизайн без live RPC.
/// Перед прод-проходом: `enabled = false`.
abstract final class BonusMock {
  static const bool enabled = false;

  static const salonId = 'mock_bonus_host_salon';
  static const barberId = 'mock_bonus_host_barber';
  static const cafeId = 'mock_bonus_host_cafe';

  static List<BonusAccountItem> accounts() => const [
        BonusAccountItem(
          hostId: salonId,
          hostDisplayName: 'Салон Beauty на Абая',
          hostUsername: 'beauty_abay',
          balance: 1240,
        ),
        BonusAccountItem(
          hostId: barberId,
          hostDisplayName: 'Barber Lab',
          hostUsername: 'barberlab',
          balance: 380,
        ),
        BonusAccountItem(
          hostId: cafeId,
          hostDisplayName: 'Кафе Clover',
          hostUsername: 'cafe_clover',
          balance: 95,
        ),
      ];

  static List<BonusHistoryEntry> historyFor(String hostId) {
    final now = DateTime.now();
    switch (hostId) {
      case salonId:
        return [
          BonusHistoryEntry(
            id: 'bh_s1',
            title: 'Стрижка и укладка',
            subtitle: 'Начисление за визит',
            amount: 80,
            occurredAt: now.subtract(const Duration(days: 2, hours: 3)),
            isCredit: true,
            source: 'booking_service',
          ),
          BonusHistoryEntry(
            id: 'bh_s2',
            title: 'Окрашивание',
            subtitle: 'Списание при записи',
            amount: 200,
            occurredAt: now.subtract(const Duration(days: 2, hours: 3, minutes: 1)),
            isCredit: false,
            source: 'booking_payment',
          ),
          BonusHistoryEntry(
            id: 'bh_s3',
            title: 'Маникюр',
            subtitle: 'Начисление за визит',
            amount: 50,
            occurredAt: now.subtract(const Duration(days: 9)),
            isCredit: true,
            source: 'booking_service',
          ),
          BonusHistoryEntry(
            id: 'bh_s4',
            title: 'Приветственные бонусы',
            subtitle: 'Подарок салона',
            amount: 100,
            occurredAt: now.subtract(const Duration(days: 30)),
            isCredit: true,
            source: 'welcome',
          ),
          BonusHistoryEntry(
            id: 'bh_s5',
            title: 'Укладка',
            subtitle: 'Списание при записи',
            amount: 120,
            occurredAt: now.subtract(const Duration(days: 31)),
            isCredit: false,
            source: 'booking_payment',
          ),
        ];
      case barberId:
        return [
          BonusHistoryEntry(
            id: 'bh_b1',
            title: 'Мужская стрижка',
            subtitle: 'Начисление за визит',
            amount: 40,
            occurredAt: now.subtract(const Duration(days: 5)),
            isCredit: true,
            source: 'booking_service',
          ),
          BonusHistoryEntry(
            id: 'bh_b2',
            title: 'Борода',
            subtitle: 'Списание при записи',
            amount: 60,
            occurredAt: now.subtract(const Duration(days: 12)),
            isCredit: false,
            source: 'booking_payment',
          ),
          BonusHistoryEntry(
            id: 'bh_b3',
            title: 'Комплекс',
            subtitle: 'Начисление за визит',
            amount: 70,
            occurredAt: now.subtract(const Duration(days: 20)),
            isCredit: true,
            source: 'booking_service',
          ),
        ];
      case cafeId:
        return [
          BonusHistoryEntry(
            id: 'bh_c1',
            title: 'Ланч-сет',
            subtitle: 'Начисление за визит',
            amount: 25,
            occurredAt: now.subtract(const Duration(days: 1, hours: 4)),
            isCredit: true,
            source: 'booking_service',
          ),
          BonusHistoryEntry(
            id: 'bh_c2',
            title: 'Кофе и десерт',
            subtitle: 'Списание при записи',
            amount: 30,
            occurredAt: now.subtract(const Duration(days: 7)),
            isCredit: false,
            source: 'booking_payment',
          ),
        ];
      default:
        return const [];
    }
  }

  static int balanceFor(String hostId) {
    for (final a in accounts()) {
      if (a.hostId == hostId) return a.balance;
    }
    return 0;
  }
}
