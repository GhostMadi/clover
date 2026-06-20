import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:flutter/material.dart';

class BookingListDetailBody extends StatelessWidget {
  const BookingListDetailBody({super.key, required this.item});

  final BookingListItem item;

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
                const SizedBox(height: 6),
                BookingListStatusChip(status: item.status, label: item.statusLabel),
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

class BookingListStatusChip extends StatelessWidget {
  const BookingListStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  final BookingListStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      BookingListStatus.pending => (AppColors.surfaceSoft, AppColors.subTextColor),
      BookingListStatus.confirmed => (AppColors.successSoft.withValues(alpha: 0.7), AppColors.primary),
      BookingListStatus.completed => (AppColors.surfaceSoft, AppColors.textColor),
      BookingListStatus.cancelled => (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
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
