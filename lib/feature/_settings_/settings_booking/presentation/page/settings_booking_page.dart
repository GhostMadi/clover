import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_profile_/profile_page/data/profile_booking_shortcut_store.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Настройки сервиса «Запись»: ярлыки профиля и переходы в сервис.
@RoutePage()
class SettingsBookingPage extends StatefulWidget {
  const SettingsBookingPage({super.key});

  @override
  State<SettingsBookingPage> createState() => _SettingsBookingPageState();
}

class _SettingsBookingPageState extends State<SettingsBookingPage> {
  late final ProfileBookingShortcutStore _bookingShortcutStore;
  bool _bookingShortcutLoading = true;

  @override
  void initState() {
    super.initState();
    _bookingShortcutStore = sl<ProfileBookingShortcutStore>();
    _loadShortcut();
  }

  Future<void> _loadShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _bookingShortcutLoading = false);
      return;
    }
    await _bookingShortcutStore.load(uid);
    if (mounted) setState(() => _bookingShortcutLoading = false);
  }

  Future<void> _setBookingShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _bookingShortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

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
            const SettingsTileSectionTitle('Профиль'),
            AppTileGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSwitchRow(
                    title: 'Кнопка «Запись» в профиле',
                    subtitle: 'Быстрый переход к записям под кнопкой «Редактировать»',
                    value: _bookingShortcutStore.visible.value,
                    enabled: !_bookingShortcutLoading,
                    onChanged: _bookingShortcutLoading ? null : _setBookingShortcut,
                    service: kBookingService,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}
