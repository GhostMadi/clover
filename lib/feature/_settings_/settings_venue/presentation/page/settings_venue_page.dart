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

/// Настройки → Бронь: список заведений (моки).
@RoutePage()
class SettingsVenuePage extends StatelessWidget {
  const SettingsVenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = venueServiceAccent(context.colors);

    return SettingsScreenShell(
      title: 'Бронь',
      service: kVenueService,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          const VenueMockBanner(
            text: 'Моки · билеты, места и схема. Редактор плана — на сайте.',
          ),
          const SizedBox(height: 16),
          const SettingsTileSectionTitle('Заведения'),
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
          const SettingsTileSectionTitle('Клиент'),
          AppTileGroup(
            children: [
              AppTile(
                title: 'Мои брони',
                subtitle: 'Запросы и подтверждённые (мок)',
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
            'Процесс: docs/business/venue-seating.md',
            style: AppTextStyle.base(12, color: context.colors.subTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
