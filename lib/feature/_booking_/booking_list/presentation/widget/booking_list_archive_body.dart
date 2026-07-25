import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_action_card.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_card.dart';
import 'package:flutter/material.dart';

class BookingListArchiveBody extends StatelessWidget {
  const BookingListArchiveBody({
    super.key,
    required this.forgotten,
    required this.history,
    required this.cancelled,
    required this.updatingIds,
    required this.onMarkCompleted,
    required this.onMarkNoShow,
    required this.onOpenItem,
  });

  final List<BookingListItem> forgotten;
  final List<BookingListItem> history;
  final List<BookingListItem> cancelled;
  final Set<String> updatingIds;
  final ValueChanged<BookingListItem> onMarkCompleted;
  final ValueChanged<BookingListItem> onMarkNoShow;
  final ValueChanged<BookingListItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final historyGroups = BookingHostInbox.groupByDay(history);
    final cancelledGroups = BookingHostInbox.groupByDay(cancelled);
    final isEmpty = forgotten.isEmpty && history.isEmpty && cancelled.isEmpty;

    if (isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text('Архив пока пуст'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: [
        if (forgotten.isNotEmpty) ...[
          _SectionTitle(
            title: 'Требуют закрытия',
            subtitle: 'Визит закончился, статус ещё не отмечен',
            accent: AppColors.functionalSoftOrangeIcon,
          ),
          const SizedBox(height: 10),
          for (final item in forgotten) ...[
            BookingListActionCard(
              item: item,
              emphasize: true,
              primaryLabel: 'Был',
              secondaryLabel: 'Не пришёл',
              isUpdating: updatingIds.contains(item.id),
              onPrimary: () => onMarkCompleted(item),
              onSecondary: () => onMarkNoShow(item),
              onTap: () => onOpenItem(item),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: forgotten.isEmpty && history.isNotEmpty,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'История записей',
              style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              history.isEmpty ? 'Пока пусто' : '${history.length}',
              style: AppTextStyle.base(12, color: AppColors.subTextColor),
            ),
            children: [
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Завершённых визитов пока нет'),
                )
              else
                for (final entry in historyGroups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        BookingHostInbox.archiveDayLabel(entry.key),
                        style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  for (final item in entry.value) ...[
                    BookingListCard(item: item, onTap: () => onOpenItem(item)),
                    const SizedBox(height: 8),
                  ],
                ],
            ],
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'Отменённые',
              style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              cancelled.isEmpty ? 'Пока пусто' : '${cancelled.length}',
              style: AppTextStyle.base(12, color: AppColors.subTextColor),
            ),
            children: [
              if (cancelled.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Отменённых записей нет'),
                )
              else
                for (final entry in cancelledGroups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        BookingHostInbox.archiveDayLabel(entry.key),
                        style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  for (final item in entry.value) ...[
                    BookingListCard(item: item, onTap: () => onOpenItem(item)),
                    const SizedBox(height: 8),
                  ],
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyle.base(16, color: accent, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyle.base(13, color: AppColors.subTextColor)),
      ],
    );
  }
}
