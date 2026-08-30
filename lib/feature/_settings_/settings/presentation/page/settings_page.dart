import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: 'Настройки',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Ресурсы'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Ресурсы',
                  subtitle: 'Местоположения и другие справочники',
                  icon: AppIcons.inventory.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsResourcesRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Сервисы'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Запись',
                  icon: AppIcons.calendarMonth.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingListRoute()),
                ),
                AppTile(
                  title: 'Бонусы',
                  subtitle: 'Программа лояльности для клиентов',
                  icon: AppIcons.giftCard.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const BonusProgramSettingsRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Архивы'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Архивы',
                  subtitle: 'Публикации, ивенты и кластеры',
                  icon: AppIcons.archive.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsArchiveRoute()),
                ),
                AppTile(
                  title: 'Сохраненные посты',
                  subtitle: 'Посты, которые вы сохранили',
                  icon: AppIcons.bookmarkOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SavedPostsRoute()),
                ),
              ],
            ),
            const SettingsTileSectionTitle('Аккаунт'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Аккаунт',
                  subtitle: 'Язык, тема и выход',
                  icon: AppIcons.personOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsAccountRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('О приложении'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'О приложении',
                  subtitle: 'Версия и онбординг',
                  icon: AppIcons.infoOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const AboutRoute()),
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
