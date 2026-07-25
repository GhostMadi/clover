import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';

class BonusHistoryPageResult {
  const BonusHistoryPageResult({
    required this.balance,
    required this.items,
    required this.hasMore,
  });

  final int balance;
  final List<BonusHistoryEntry> items;
  final bool hasMore;
}
