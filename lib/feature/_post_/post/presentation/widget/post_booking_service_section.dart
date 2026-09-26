import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_post_/post/data/models/post_booking_service_summary.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// CTA «Записаться на эту услугу» на деталке поста.
class PostBookingServiceSection extends StatelessWidget {
  const PostBookingServiceSection({
    super.key,
    required this.hostId,
    required this.hostDisplayName,
    required this.service,
    this.isLoading = false,
    this.showBookAction = true,
  });

  final String hostId;
  final String hostDisplayName;
  final PostBookingServiceSummary? service;
  final bool isLoading;
  final bool showBookAction;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceSoftGreen.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.borderCardGreen.withValues(alpha: 0.65)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.post_service_loading,
                style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final linked = service;
    if (linked == null || !linked.isActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceSoftGreen.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.borderCardGreen.withValues(alpha: 0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.post_book_service,
              style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              linked.subtitle,
              style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            if (showBookAction) ...[
              const SizedBox(height: 12),
              AppButton(
                text: context.l10n.post_book_this_service,
                isExpanded: true,
                onTap: () => context.router.push(
                  BookingClientRoute(
                    hostId: hostId,
                    hostDisplayName: hostDisplayName,
                    initialServiceId: linked.id,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
