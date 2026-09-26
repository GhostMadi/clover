import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Настройки → Бронь: список заведений (моки).
@RoutePage()
class SettingsVenuePage extends StatelessWidget {
  const SettingsVenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = venueServiceAccent(context.colors);

    return SettingsScreenShell(
      title: context.l10n.venue_hub_title,
      service: kVenueService,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          VenueMockBanner(
            text: context.l10n.venue_hub_mock_subtitle,
          ),
          const SizedBox(height: 16),
          SettingsTileSectionTitle(context.l10n.venue_establishments),
          AppTileGroup(
            children: [
              for (final venue in VenueMockCatalog.venues)
                AppTile(
                  title: venue.name,
                  subtitle: venue.subtitle,
                  icon: AppIcons.ticket.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(
                    VenueHubRoute(venueId: venue.id, venueName: venue.name),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsTileSectionTitle(context.l10n.settings_venue_client),
          AppTileGroup(
            children: [
              AppTile(
                title: context.l10n.venue_my_bookings,
                subtitle: context.l10n.venue_requests_confirmed,
                icon: AppIcons.event.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(const MyVenueReservationsRoute()),
              ),
            ],
          ),
          SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          Text(
            context.l10n.venue_process_doc,
            style: AppTextStyle.base(12, color: context.colors.subTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
