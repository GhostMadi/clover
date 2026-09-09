import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

/// Настройки сервиса «Запись». Кнопка в профиле — по тегу `booking`, не prefs.
@RoutePage()
class SettingsBookingPage extends StatelessWidget {
  const SettingsBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return SettingsScreenShell(
      title: 'Запись',
      service: kBookingService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Сервис'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Мои записи',
                  subtitle: 'Календарь и визиты',
                  icon: AppIcons.calendarMonth.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingListRoute()),
                ),
                AppTile(
                  title: 'Услуги',
                  subtitle: 'Цены, длительность, исполнители',
                  icon: AppIcons.designServices.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingCreateRoute()),
                ),
                AppTile(
                  title: 'Аналитика',
                  subtitle: 'Записи, услуги и исполнители',
                  icon: AppIcons.insights.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingAnalyticsRoute()),
                ),
                AppTile(
                  title: 'Настройки расписания',
                  subtitle: 'Часы работы, горизонт, отсутствия',
                  icon: AppIcons.settingsOutlined.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingScheduleSettingsRoute()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
