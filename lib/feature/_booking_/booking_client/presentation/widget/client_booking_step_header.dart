import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Заголовок шага во флоу записи клиента.
class ClientBookingStepHeader extends StatelessWidget {
  const ClientBookingStepHeader({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
  });

  final int step;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.soft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$step',
            style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyle.base(12, color: context.colors.subTextColor, height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Короткая шапка хозяина вверху экрана записи.
class ClientBookingHostHeader extends StatelessWidget {
  const ClientBookingHostHeader({super.key, required this.hostDisplayName});

  final String hostDisplayName;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.eventAvailable.icon, size: 20, color: accent.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Запись к',
                  style: AppTextStyle.base(
                    12,
                    color: accent.onSoft.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hostDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(
                    16,
                    color: accent.onSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
