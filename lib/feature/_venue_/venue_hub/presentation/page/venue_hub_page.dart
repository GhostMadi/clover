import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class VenueHubPage extends StatelessWidget {
  const VenueHubPage({
    super.key,
    required this.venueId,
    this.venueName,
  });

  final String venueId;
  final String? venueName;

  @override
  Widget build(BuildContext context) {
    final venue = VenueMockCatalog.venueById(venueId);
    final accent = venueServiceAccent(context.colors);
    final title = venueName?.trim().isNotEmpty == true
        ? venueName!.trim()
        : (venue?.name ?? context.l10n.venue_establishment);

    if (venue == null) {
      return VenueScreenShell(
        title: context.l10n.venue_establishment,
        body: Center(
          child: Text(
            context.l10n.venue_not_found,
            style: AppTextStyle.base(15, color: context.colors.subTextColor),
          ),
        ),
      );
    }

    return VenueScreenShell(
      title: title,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          VenueMockBanner(text: venue.subtitle),
          const SizedBox(height: 16),
          SettingsTileSectionTitle(context.l10n.venue_catalog),
          AppTileGroup(
            children: [
              AppTile(
                title: context.l10n.venue_tickets_fares,
                subtitle: context.l10n.venue_level_a,
                icon: AppIcons.ticket.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueTicketsRoute(venueId: venueId)),
              ),
              AppTile(
                title: context.l10n.venue_places_list,
                subtitle: context.l10n.venue_level_b,
                icon: AppIcons.eventSeat.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueSeatsRoute(venueId: venueId)),
              ),
              AppTile(
                title: context.l10n.venue_plan_schema,
                subtitle: venue.hasPlan ? context.l10n.venue_level_c_preview : context.l10n.venue_no_schema_hint,
                icon: AppIcons.layers.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenuePlanRoute(venueId: venueId)),
              ),
              AppTile(
                title: context.l10n.venue_sessions_slots,
                subtitle: context.l10n.venue_when_bookable,
                icon: AppIcons.event.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueSessionsRoute(venueId: venueId)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsTileSectionTitle(context.l10n.venue_operations),
          AppTileGroup(
            children: [
              AppTile(
                title: context.l10n.booking_inbox_title,
                subtitle: context.l10n.venue_requests_to_confirm,
                icon: AppIcons.mail.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueInboxRoute(venueId: venueId)),
              ),
              AppTile(
                title: context.l10n.venue_client_view,
                subtitle: context.l10n.venue_request_preview,
                icon: AppIcons.visibility.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueClientRoute(venueId: venueId)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
