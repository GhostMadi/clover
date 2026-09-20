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
class VenueTicketsPage extends StatelessWidget {
  const VenueTicketsPage({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final tickets = VenueMockCatalog.ticketsFor(venueId);
    final accent = venueServiceAccent(context.colors);

    return VenueScreenShell(
      title: 'Билеты / тарифы',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          const VenueMockBanner(text: 'Уровень A · без схемы. Клиент выбирает тариф и qty.'),
          const SizedBox(height: 16),
          AppTileGroup(
            children: [
              for (final ticket in tickets)
                AppTile(
                  title: ticket.title,
                  subtitle: '${ticket.priceHint} · осталось ${ticket.remaining}',
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  trailing: Text(
                    'мок',
                    style: AppTextStyle.base(12, color: context.colors.subTextColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
