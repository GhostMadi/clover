import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_step_header.dart';
import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

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
        ClientBookingStepHeader(
          step: 4,
          title: context.l10n.booking_time,
          subtitle: context.l10n.booking_slots_for_day,
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          Text(
            context.l10n.booking_no_free_slots_day,
            style: AppTextStyle.base(13, color: context.colors.subTextColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots) _SlotChip(slot: slot, onTap: () => onSlotTap(slot)),
            ],
          ),
        if (slots.any((s) =>
            s.status == ClientBookingSlotStatus.myConflict ||
            s.status == ClientBookingSlotStatus.hostBusy)) ...[
          const SizedBox(height: 12),
          const _Legend(),
        ],
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
    final accent = bookingServiceAccent(context.colors);
    final (bg, fg, border, enabled) = switch (slot.status) {
      ClientBookingSlotStatus.selected => (accent.cta, accent.ctaForeground, accent.cta, true),
      ClientBookingSlotStatus.available => (
          context.colors.surface,
          context.colors.textColor,
          context.colors.border.withValues(alpha: 0.8),
          true,
        ),
      ClientBookingSlotStatus.myConflict => (
          context.colors.functionalSoftRed,
          context.colors.functionalSoftRedIcon,
          context.colors.borderCardRed,
          true,
        ),
      ClientBookingSlotStatus.hostBusy => (
          context.colors.surfaceMuted,
          context.colors.iconMuted,
          context.colors.borderSoft,
          false,
        ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled || slot.status == ClientBookingSlotStatus.myConflict ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            slot.timeLabel,
            style: AppTextStyle.base(14, color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(color: context.colors.borderCardRed, label: context.l10n.booking_conflict_with_yours),
        _LegendItem(color: context.colors.borderSoft, label: context.l10n.booking_busy),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyle.base(11, color: context.colors.subTextColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
