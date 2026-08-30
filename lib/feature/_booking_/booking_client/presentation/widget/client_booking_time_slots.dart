import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';
import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:flutter/material.dart';

class ClientBookingTimeSlots extends StatelessWidget {
  const ClientBookingTimeSlots({
    super.key,
    required this.slots,
    required this.onSlotTap,
  });

  final List<ClientBookingSlot> slots;
  final ValueChanged<ClientBookingSlot> onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Время',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in slots) _SlotChip(slot: slot, onTap: () => onSlotTap(slot)),
          ],
        ),
        const SizedBox(height: 10),
        _Legend(),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.onTap});

  final ClientBookingSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (slot.status) {
      ClientBookingSlotStatus.selected => (context.colors.primary, context.colors.textInverse, context.colors.primary),
      ClientBookingSlotStatus.available => (context.colors.surface, context.colors.textColor, context.colors.borderCardGreen),
      ClientBookingSlotStatus.myConflict => (
          context.colors.functionalSoftRed,
          context.colors.functionalSoftRedIcon,
          context.colors.borderCardRed,
        ),
      ClientBookingSlotStatus.hostBusy => (context.colors.surfaceSoft, context.colors.subTextColor, context.colors.borderSoft),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border.withValues(alpha: 0.85)),
          ),
          child: Text(
            slot.timeLabel,
            style: AppTextStyle.base(13, color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendItem(color: context.colors.primary, label: 'Выбрано'),
        _LegendItem(color: context.colors.borderCardGreen, label: 'Свободно'),
        _LegendItem(color: context.colors.borderCardRed, label: 'Ваш конфликт'),
        _LegendItem(color: context.colors.borderSoft, label: 'Занято'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(label, style: AppTextStyle.base(11, color: context.colors.subTextColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
