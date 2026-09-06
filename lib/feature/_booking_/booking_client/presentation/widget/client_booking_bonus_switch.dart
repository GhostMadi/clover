import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:clover/feature/_booking_/booking_client/data/client_booking_bonus_preview.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:flutter/material.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';

class ClientBookingBonusSwitch extends StatelessWidget {
  const ClientBookingBonusSwitch({
    super.key,
    required this.service,
    required this.balance,
    required this.value,
    required this.onChanged,
  });

  final BookingService service;
  final int balance;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (service.bonusPayPercent <= 0) return const SizedBox.shrink();

    final balanceLabel = '${BonusFormat.formatBalance(balance)} ${BonusFormat.bonusWord(balance)}';
    final expectedSpend = ClientBookingBonusPreview.expectedSpend(
      service: service,
      balance: balance,
      useBonuses: value,
    );

    final subtitle = value
        ? 'На балансе $balanceLabel. После визита спишем до $expectedSpend '
            '(${service.bonusPayPercent}% цены). Остаток — на месте.'
        : 'На балансе $balanceLabel. Бонусы за этот визит не списываем.';

    return BookingSwitchRow(
      title: 'Оплатить бонусами',
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
}
