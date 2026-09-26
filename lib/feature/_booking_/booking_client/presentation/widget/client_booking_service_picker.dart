import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_step_header.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

class ClientBookingServicePicker extends StatelessWidget {
  const ClientBookingServicePicker({
    super.key,
    required this.services,
    required this.selectedId,
    required this.onSelected,
    this.step = 1,
  });

  final List<BookingService> services;
  final String? selectedId;
  final ValueChanged<BookingService> onSelected;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientBookingStepHeader(
          step: step,
          title: context.l10n.booking_service,
          subtitle: context.l10n.booking_what_to_do,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < services.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ServiceTile(
            service: services[i],
            selected: services[i].id == selectedId,
            onTap: () => onSelected(services[i]),
          ),
        ],
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final BookingService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Material(
      color: selected ? accent.soft : context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent.ctaBorder : context.colors.border.withValues(alpha: 0.7),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.surface.withValues(alpha: 0.7)
                      : context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(service.emojiText, style: AppTextStyle.emoji(22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        15,
                        color: selected ? accent.onSoft : context.colors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.displaySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        12,
                        color: selected
                            ? accent.onSoft.withValues(alpha: 0.7)
                            : context.colors.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service.priceLabel,
                    style: AppTextStyle.base(14, color: accent.icon, fontWeight: FontWeight.w800),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 4),
                    Icon(AppIcons.checkCircle.icon, size: 18, color: accent.icon),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
