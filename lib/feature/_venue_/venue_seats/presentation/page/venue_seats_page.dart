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
class VenueSeatsPage extends StatelessWidget {
  const VenueSeatsPage({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final seats = VenueMockCatalog.seatsFor(venueId);
    final colors = context.colors;

    return VenueScreenShell(
      title: 'Места списком',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          const VenueMockBanner(text: 'Уровень B · те же bookable, что на схеме.'),
          const SizedBox(height: 12),
          const VenueStateLegend(),
          const SizedBox(height: 16),
          if (seats.isEmpty)
            Text(
              'У этого заведения пока нет мест — только билеты.',
              style: AppTextStyle.base(14, color: colors.subTextColor),
            )
          else
            AppTileGroup(
              children: [
                for (final seat in seats)
                  AppTile(
                    title: seat.label,
                    subtitle: [
                      'до ${seat.capacity} гост.',
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
