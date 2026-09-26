import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_step_header.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

class ClientBookingExecutorPicker extends StatelessWidget {
  const ClientBookingExecutorPicker({
    super.key,
    required this.executors,
    required this.selectedId,
    required this.onSelected,
    this.step = 2,
  });

  final List<BookingServiceExecutor> executors;
  final String? selectedId;
  final ValueChanged<BookingServiceExecutor> onSelected;
  final int step;

  @override
  Widget build(BuildContext context) {
    if (executors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientBookingStepHeader(
          step: step,
          title: context.l10n.booking_master,
          subtitle: context.l10n.booking_who_does_service,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < executors.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ExecutorTile(
            executor: executors[i],
            selected: executors[i].id == selectedId,
            onTap: () => onSelected(executors[i]),
          ),
        ],
      ],
    );
  }
}

class _ExecutorTile extends StatelessWidget {
  const _ExecutorTile({
    required this.executor,
    required this.selected,
    required this.onTap,
  });

  final BookingServiceExecutor executor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final initial = executor.displayName.trim().isEmpty
        ? '?'
        : executor.displayName.characters.first.toUpperCase();

    return Material(
      color: selected ? accent.soft : context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent.ctaBorder : context.colors.border.withValues(alpha: 0.7),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? context.colors.surface.withValues(alpha: 0.75)
                    : accent.soft.withValues(alpha: 0.55),
                child: Text(
                  initial,
                  style: AppTextStyle.base(14, color: accent.icon, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  executor.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(
                    14,
                    color: selected ? accent.onSoft : context.colors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected) Icon(AppIcons.checkCircle.icon, size: 20, color: accent.icon),
            ],
          ),
        ),
      ),
    );
  }
}
