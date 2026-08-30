import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsResourcesPage extends StatelessWidget {
  const SettingsResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: 'Ресурсы',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Справочники'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Местоположения',
                  subtitle: 'Адреса, точки на карте, зоны доставки',
                  icon: AppIcons.locationOn.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const LocationRoute()),
                ),
                AppTile(
                  title: 'Фильтры',
                  subtitle: 'Категории и значения для фильтрации',
                  icon: AppIcons.tune.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsFiltersRoute()),
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
