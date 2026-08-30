/// Строка `public.currencies`.
class CurrencyModel {
  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.isActive,
    required this.sortOrder,
  });

  final String code;
  final String symbol;
  final bool isActive;
  final int sortOrder;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: (json['code'] as String).trim().toUpperCase(),
      symbol: (json['symbol'] as String?)?.trim() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'symbol': symbol,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}
