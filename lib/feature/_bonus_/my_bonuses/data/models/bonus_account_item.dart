import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';

/// Аккаунт (салон / магазин), где у клиента есть бонусы.
class BonusAccountItem {
  const BonusAccountItem({
    required this.hostId,
    required this.hostDisplayName,
    required this.balance,
    this.hostUsername,
    this.avatarUrl,
  });

  final String hostId;
  final String hostDisplayName;
  final String? hostUsername;
  final String? avatarUrl;
  final int balance;

  String get formattedBalance => BonusFormat.formatBalance(balance);

  String get balanceLabel => '$formattedBalance ${BonusFormat.bonusWord(balance)}';

  String get usernameLabel {
    final raw = hostUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  BonusAccountItem copyWith({
    String? hostId,
    String? hostDisplayName,
    String? hostUsername,
    String? avatarUrl,
    int? balance,
  }) {
    return BonusAccountItem(
      hostId: hostId ?? this.hostId,
      hostDisplayName: hostDisplayName ?? this.hostDisplayName,
      hostUsername: hostUsername ?? this.hostUsername,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      balance: balance ?? this.balance,
    );
  }
}
