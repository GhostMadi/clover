import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

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
      title: 'Мои брони',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          const VenueMockBanner(text: 'Клиентский список запросов (мок).'),
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
              'Пока пусто',
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
        ],
      ),
    );
  }
}
