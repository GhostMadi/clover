import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

@RoutePage()
class MyVenueReservationsPage extends StatelessWidget {
  const MyVenueReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = venueServiceAccent(context.colors);
    final mine = [
      ...VenueMockCatalog.reservationsFor('cafe').take(2),
      ...VenueMockCatalog.reservationsFor('poetry').take(1),
    ];

    return VenueScreenShell(
      title: context.l10n.venue_my_bookings,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          VenueMockBanner(text: context.l10n.venue_client_requests_mock),
          const SizedBox(height: 16),
          AppTileGroup(
            children: [
              for (final item in mine)
                AppTile(
                  title: item.placeLabel,
                  subtitle:
                      '${item.whenLabel} · ${VenueMockCatalog.statusLabel(item.status)}',
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                ),
            ],
          ),
          if (mine.isEmpty)
            Text(
              context.l10n.venue_empty_for_now,
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
        ],
      ),
    );
  }
}
