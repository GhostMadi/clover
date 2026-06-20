import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/settings/presentation/widget/settings_tile_section.dart';
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
                  icon: Icons.inventory_2_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsResourcesRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Работа'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Работа',
                  subtitle: 'Работодатель, работник и заявки',
                  icon: Icons.work_outline_rounded,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsWorkRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Сервисы'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Запись',
                  icon: Icons.calendar_month_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(const BookingListRoute()),
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
                  icon: Icons.archive_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsArchiveRoute()),
                ),
              ],
            ),
            const SettingsTileSectionTitle('Аккаунт'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Аккаунт',
                  subtitle: 'Язык, тема и выход',
                  icon: Icons.person_outline_rounded,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsAccountRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // const SettingsTileSectionTitle('Общее'),
            // AppTileGroup(
            //   children: [
            //     AppTile(
            //       title: 'Язык',
            //       subtitle: 'Русский',
            //       icon: AppIcons.language.icon,
            //       showChevron: true,
            //       onTap: () {},
            //     ),
            //     AppTile(
            //       title: 'Тема',
            //       subtitle: 'Системная',
            //       icon: AppIcons.theme.icon,
            //       showChevron: true,
            //       onTap: () {},
            //     ),
            //     AppTile(
            //       title: 'О приложении',
            //       subtitle: 'Версия 1.0.0',
            //       icon: Icons.info_outline_rounded,
            //       showChevron: true,
            //       onTap: () {},
            //     ),
            //   ],
            // ),
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}
