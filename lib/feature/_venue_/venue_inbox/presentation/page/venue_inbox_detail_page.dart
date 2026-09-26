import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
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
        title: context.l10n.venue_request,
        body: Center(
          child: Text(
            context.l10n.venue_request_not_found,
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
          VenueMockBanner(text: context.l10n.venue_actions_mock),
          const SizedBox(height: 16),
          _InfoCard(
            rows: [
              (context.l10n.catalog_group_place, item.placeLabel),
              (context.l10n.venue_when, item.whenLabel),
              (context.l10n.venue_guests, '${item.guests}'),
              (context.l10n.venue_status, VenueMockCatalog.statusLabel(item.status)),
              if (item.comment.trim().isNotEmpty) (context.l10n.venue_comment, item.comment),
            ],
          ),
          const SizedBox(height: 20),
          VenuePrimaryButton(
            text: context.l10n.common_confirm,
            onTap: () => AppSnackBar.show(context, message: context.l10n.venue_mock_confirmed),
          ),
          const SizedBox(height: 10),
          VenuePrimaryButton(
            text: context.l10n.common_reject,
            onTap: () => AppSnackBar.show(context, message: context.l10n.venue_mock_rejected),
          ),
          const SizedBox(height: 10),
          VenuePrimaryButton(
            text: context.l10n.venue_extra_pay,
            onTap: () => AppSnackBar.show(context, message: context.l10n.venue_mock_extra_pay),
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
