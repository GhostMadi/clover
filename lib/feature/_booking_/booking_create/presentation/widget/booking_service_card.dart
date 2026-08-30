import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:flutter/material.dart';

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

  String? get _executorsLabel {
    if (executors.isNotEmpty) {
      if (executors.length == 1) return executors.first.displayName;
      final names = executors.take(2).map((e) => e.displayName).join(', ');
      if (executors.length > 2) return '$names и ещё ${executors.length - 2}';
      return names;
    }
    if (service.executorIds.isEmpty) return null;
    return '${service.executorIds.length} мастер(ов)';
  }

  @override
  Widget build(BuildContext context) {
    final executorsLabel = _executorsLabel;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              _EmojiBadge(emoji: service.emojiText),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.displaySubtitle,
                      style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w500),
                    ),
                    if (executorsLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Исполнители: $executorsLabel',
                        style: AppTextStyle.base(12, color: context.colors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (service.description != null && service.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                service.priceLabel,
                style: AppTextStyle.base(15, color: context.colors.primary, fontWeight: FontWeight.w800),
              ),
            ],
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
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceSoftGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.borderCardGreen.withValues(alpha: 0.7)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26, height: 1)),
    );
  }
}
