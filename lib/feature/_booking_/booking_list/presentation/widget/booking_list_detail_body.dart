import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_visit_progress_section.dart';
import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:flutter/material.dart';

class BookingListDetailBody extends StatelessWidget {
  const BookingListDetailBody({
    super.key,
    required this.item,
    this.isUpdatingVisit = false,
    this.onMarkVisitStatus,
    this.onEmergencyAction,
    this.onRevertVisit,
  });

  final BookingListItem item;
  final bool isUpdatingVisit;
  final ValueChanged<BookingStatus>? onMarkVisitStatus;
  final ValueChanged<BookingHostEmergencyAction>? onEmergencyAction;
  final VoidCallback? onRevertVisit;

  static const _monthLabels = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return '${date.day} ${_monthLabels[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = item.startsAtDate?.toLocal();
    final end = item.endsAtDate?.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          _HeaderCard(item: item),
          const SizedBox(height: 16),
          _Section(
            title: 'Клиент',
            children: [
              _DetailRow(label: 'Имя', value: item.clientName),
              if (item.clientPhone != null && item.clientPhone!.isNotEmpty)
                _DetailRow(label: 'Телефон', value: item.clientPhone!),
              if (item.clientUsernameLabel.isNotEmpty)
                _DetailRow(label: 'Никнейм', value: item.clientUsernameLabel),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Время',
            children: [
              _DetailRow(label: 'Дата и начало', value: _formatDateTime(start)),
              _DetailRow(
                label: 'Окончание',
                value: end == null ? '—' : '${_formatTime(end)} · $durationLabel',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Услуга',
            children: [
              _DetailRow(label: 'Название', value: item.serviceTitle),
              _DetailRow(label: 'Длительность', value: durationLabel),
              _DetailRow(label: 'Цена', value: item.priceLabel),
              if (item.participantsCount > 1)
                _DetailRow(label: 'Участников', value: '${item.participantsCount}'),
            ],
          ),
          if (item.executorName != null && item.executorName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Исполнитель',
              children: [
                _DetailRow(label: 'Назначен', value: item.executorName!),
              ],
            ),
          ],
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Заметка клиента',
              children: [
                _DetailRow(label: 'Комментарий', value: item.notes!.trim(), multiline: true),
              ],
            ),
          ],
          if (item.createdAtDate != null) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Системное',
              children: [
                _DetailRow(label: 'Создана', value: _formatDateTime(item.createdAtDate!.toLocal())),
              ],
            ),
          ],
          if (onMarkVisitStatus != null && onEmergencyAction != null) ...[
            const SizedBox(height: 16),
            BookingVisitProgressSection(
              item: item,
              isLoading: isUpdatingVisit,
              onMarkStatus: onMarkVisitStatus!,
              onEmergencyAction: onEmergencyAction!,
              onRevert: onRevertVisit,
            ),
          ],
        ],
      );
  }

  String get durationLabel => '${item.durationMinutes} мин';
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});

  final BookingListItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceSoftGreen.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.borderCardGreen.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(item.serviceEmoji, style: const TextStyle(fontSize: 28, height: 1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.serviceTitle,
                  style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                BookingListStatusChip(
                  status: item.status,
                  label: item.statusLabel,
                  isUnmarked: item.isVisitUnmarked,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.base(
                14,
                color: context.colors.textColor,
                fontWeight: FontWeight.w600,
                height: multiline ? 1.35 : 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingListStatusChip extends StatelessWidget {
  const BookingListStatusChip({
    super.key,
    required this.status,
    required this.label,
    this.isUnmarked = false,
  });

  final BookingStatus status;
  final String label;
  final bool isUnmarked;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = isUnmarked
        ? (context.colors.functionalSoftOrange, context.colors.functionalSoftOrangeIcon)
        : switch (status) {
            BookingStatus.pending => (context.colors.surfaceSoft, context.colors.subTextColor),
            BookingStatus.confirmed => (context.colors.successSoft.withValues(alpha: 0.7), context.colors.primary),
            BookingStatus.clientArrived => (context.colors.infoSoft, context.colors.functionalSoftBlueIcon),
            BookingStatus.inProgress => (context.colors.functionalSoftBlue, context.colors.functionalSoftBlueIcon),
            BookingStatus.completed => (context.colors.surfaceSoft, context.colors.textColor),
            BookingStatus.cancelled => (context.colors.functionalSoftRed, context.colors.functionalSoftRedIcon),
            BookingStatus.noShow => (context.colors.functionalSoftOrange, context.colors.functionalSoftOrangeIcon),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyle.base(12, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
