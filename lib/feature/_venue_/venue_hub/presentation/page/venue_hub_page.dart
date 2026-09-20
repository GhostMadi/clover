import 'package:clover/core/resources/app_icons.dart';
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
        : (venue?.name ?? 'Заведение');

    if (venue == null) {
      return VenueScreenShell(
        title: 'Заведение',
        body: Center(
          child: Text(
            'Заведение не найдено',
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
          const SettingsTileSectionTitle('Каталог'),
          AppTileGroup(
            children: [
              AppTile(
                title: 'Билеты / тарифы',
                subtitle: 'Уровень A',
                icon: AppIcons.ticket.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueTicketsRoute(venueId: venueId)),
              ),
              AppTile(
                title: 'Места списком',
                subtitle: 'Уровень B',
                icon: AppIcons.eventSeat.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueSeatsRoute(venueId: venueId)),
              ),
              AppTile(
                title: 'План / схема',
                subtitle: venue.hasPlan ? 'Уровень C · превью' : 'Нет схемы · подсказка',
                icon: AppIcons.layers.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenuePlanRoute(venueId: venueId)),
              ),
              AppTile(
                title: 'Сеансы / слоты',
                subtitle: 'Когда можно бронировать',
                icon: AppIcons.event.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueSessionsRoute(venueId: venueId)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SettingsTileSectionTitle('Операции'),
          AppTileGroup(
            children: [
              AppTile(
                title: 'Inbox',
                subtitle: 'Запросы → подтверждение',
                icon: AppIcons.mail.icon,
                iconColor: accent.icon,
                iconBackgroundColor: accent.soft,
                showChevron: true,
                onTap: () => context.router.push(VenueInboxRoute(venueId: venueId)),
              ),
              AppTile(
                title: 'Как видит клиент',
                subtitle: 'Превью запроса брони',
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
