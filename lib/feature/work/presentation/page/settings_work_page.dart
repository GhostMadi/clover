import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsWorkPage extends StatelessWidget {
  const SettingsWorkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: 'Работа',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Роль'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Вы работодатель',
                  subtitle: 'Работники и заявки в команду',
                  icon: Icons.business_center_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(const EmployerWorkRoute()),
                ),
                AppTile(
                  title: 'Вы работник',
                  subtitle: 'Работодатели и приглашения',
                  icon: Icons.badge_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(const WorkerWorkRoute()),
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
