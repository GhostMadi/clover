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
class VenueSeatsPage extends StatelessWidget {
  const VenueSeatsPage({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final seats = VenueMockCatalog.seatsFor(venueId);
    final colors = context.colors;

    return VenueScreenShell(
      title: context.l10n.venue_places_list,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          VenueMockBanner(text: context.l10n.venue_level_b_bookable),
          const SizedBox(height: 12),
          const VenueStateLegend(),
          const SizedBox(height: 16),
          if (seats.isEmpty)
            Text(
              context.l10n.venue_no_seats_tickets_only,
              style: AppTextStyle.base(14, color: colors.subTextColor),
            )
          else
            AppTileGroup(
              children: [
                for (final seat in seats)
                  AppTile(
                    title: seat.label,
                    subtitle: [
                      context.l10n.venue_seat_capacity(seat.capacity),
                      if (seat.priceHint != null) seat.priceHint!,
                      VenueMockCatalog.stateLabel(seat.state),
                    ].join(' · '),
                    iconColor: venueStateInk(colors, seat.state),
                    iconBackgroundColor: venueStateSoft(colors, seat.state),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
