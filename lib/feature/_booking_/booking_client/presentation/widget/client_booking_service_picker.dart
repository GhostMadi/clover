import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:flutter/material.dart';

class ClientBookingServicePicker extends StatelessWidget {
  const ClientBookingServicePicker({
    super.key,
    required this.services,
    required this.selectedId,
    required this.onSelected,
  });

  final List<BookingService> services;
  final String? selectedId;
  final ValueChanged<BookingService> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Услуга',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (final service in services) ...[
          _ServiceTile(
            service: service,
            selected: service.id == selectedId,
            onTap: () => onSelected(service),
          ),
          const SizedBox(height: 8),
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
    return Material(
      color: selected ? context.colors.surfaceSoftGreen.withValues(alpha: 0.55) : context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.border.withValues(alpha: 0.55),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(service.emojiText, style: const TextStyle(fontSize: 26, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.displaySubtitle,
                      style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                service.priceLabel,
                style: AppTextStyle.base(14, color: context.colors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
