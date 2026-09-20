import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Компактная строка услуги в списке хозяина.
class BookingServiceCard extends StatelessWidget {
  const BookingServiceCard({
    super.key,
    required this.service,
    this.executors = const [],
    this.onTap,
  });

  final BookingService service;
  final List<BookingServiceExecutor> executors;
  final VoidCallback? onTap;

  String? get _staffLine {
    if (executors.isEmpty) {
      if (service.executorIds.isEmpty) return null;
      return '${service.executorIds.length} мастер(ов)';
    }
    if (executors.length == 1) return executors.first.displayName;
    final names = executors.take(2).map((e) => e.displayName).join(', ');
    if (executors.length > 2) return '$names +${executors.length - 2}';
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final staffLine = _staffLine;
    final active = service.isActive;

    final metaParts = <String>[
      '${service.durationMinutes} мин',
      if (service.maxParticipants > 1) 'до ${service.maxParticipants} чел.',
    ];

    return Opacity(
      opacity: active ? 1 : 0.55,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border.withValues(alpha: 0.55)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  _EmojiBadge(emoji: service.emojiText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.base(
                                  16,
                                  color: colors.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!active) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Выкл',
                                style: AppTextStyle.base(
                                  12,
                                  color: colors.subTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metaParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(
                            13,
                            color: colors.subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (staffLine != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            staffLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(
                              12,
                              color: accent.icon,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    service.priceLabel,
                    style: AppTextStyle.base(
                      15,
                      color: accent.icon,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(emoji, style: AppTextStyle.emoji(24)),
    );
  }
}
