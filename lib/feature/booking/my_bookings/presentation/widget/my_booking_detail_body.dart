import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';
import 'package:flutter/material.dart';

class MyBookingDetailBody extends StatelessWidget {
  const MyBookingDetailBody({super.key, required this.item});

  final MyBookingItem item;

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

  String get _durationLabel => '${item.durationMinutes} мин';

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
          title: 'Мастер / салон',
          children: [
            _DetailRow(label: 'Название', value: item.hostDisplayName),
            if (item.hostUsernameLabel.isNotEmpty)
              _DetailRow(label: 'Аккаунт', value: item.hostUsernameLabel),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Время',
          children: [
            _DetailRow(label: 'Дата и начало', value: _formatDateTime(start)),
            _DetailRow(
              label: 'Окончание',
              value: end == null ? '—' : '${_formatTime(end)} · $_durationLabel',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Услуга',
          children: [
            _DetailRow(label: 'Название', value: item.serviceTitle),
            _DetailRow(label: 'Длительность', value: _durationLabel),
            _DetailRow(label: 'Цена', value: item.priceLabel),
          ],
        ),
        if (item.executorName != null && item.executorName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Исполнитель',
            children: [
              _DetailRow(label: 'Мастер', value: item.executorName!),
            ],
          ),
        ],
        if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Заметка',
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
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});

  final MyBookingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftGreen.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCardGreen.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                  style: AppTextStyle.base(18, color: AppColors.textColor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  item.hostDisplayName,
                  style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w700),
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
              style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.base(
                14,
                color: AppColors.textColor,
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
