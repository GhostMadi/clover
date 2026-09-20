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
class VenueSessionsPage extends StatelessWidget {
  const VenueSessionsPage({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final sessions = VenueMockCatalog.sessionsFor(venueId);
    final accent = venueServiceAccent(context.colors);

    return VenueScreenShell(
      title: 'Сеансы / слоты',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          const VenueMockBanner(text: 'Occasion: сеанс кино или слот ресторана.'),
          const SizedBox(height: 16),
          AppTileGroup(
            children: [
              for (final session in sessions)
                AppTile(
                  title: session.title,
                  subtitle:
                      '${session.whenLabel} · свободно ${session.freeCount}/${session.totalCount}',
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                ),
            ],
          ),
          if (sessions.isEmpty)
            Text(
              'Сеансов нет',
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
        ],
      ),
    );
  }
}
