import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class VenueInboxDetailPage extends StatelessWidget {
  const VenueInboxDetailPage({
    super.key,
    required this.venueId,
    required this.reservationId,
  });

  final String venueId;
  final String reservationId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = VenueMockCatalog.reservationsFor(venueId)
        .where((e) => e.id == reservationId)
        .firstOrNull;

    if (item == null) {
      return VenueScreenShell(
        title: 'Запрос',
        body: Center(
          child: Text(
            'Запрос не найден',
            style: AppTextStyle.base(15, color: colors.subTextColor),
          ),
        ),
      );
    }

    return VenueScreenShell(
      title: item.guestName,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          const VenueMockBanner(text: 'Действия моковые — бэка нет.'),
          const SizedBox(height: 16),
          _InfoCard(
            rows: [
              ('Место', item.placeLabel),
              ('Когда', item.whenLabel),
              ('Гостей', '${item.guests}'),
              ('Статус', VenueMockCatalog.statusLabel(item.status)),
              if (item.comment.trim().isNotEmpty) ('Комментарий', item.comment),
            ],
          ),
          const SizedBox(height: 20),
          VenuePrimaryButton(
            text: 'Подтвердить',
            onTap: () => AppSnackBar.show(context, message: 'Мок: подтверждено'),
          ),
          const SizedBox(height: 10),
          VenuePrimaryButton(
            text: 'Отклонить',
            onTap: () => AppSnackBar.show(context, message: 'Мок: отклонено'),
          ),
          const SizedBox(height: 10),
          VenuePrimaryButton(
            text: 'Нужна доплата (вне Clover)',
            onTap: () => AppSnackBar.show(context, message: 'Мок: условие доплаты'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 20, color: colors.divider),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    rows[i].$1,
                    style: AppTextStyle.base(13, color: colors.subTextColor),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: AppTextStyle.base(14, fontWeight: FontWeight.w600, color: colors.textColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
