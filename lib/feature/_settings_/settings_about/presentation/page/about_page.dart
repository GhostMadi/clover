import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/resources.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SettingsScreenShell(
      title: 'О приложении',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: context.heightByContext(12)),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    AppImages.logo,
                    height: context.heightByContext(56),
                  ),
                  SizedBox(height: context.heightByContext(12)),
                  Text(
                    'Clover',
                    style: AppTextStyle.base(
                      24,
                      color: colors.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.heightByContext(6)),
                  Text(
                    'Версия $_appVersion',
                    style: AppTextStyle.base(
                      14,
                      color: colors.subTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.heightByContext(20)),
            Text(
              'События, карта, чат и сервисы для бизнеса — '
              'чтобы жизнь была ярче, а работа проще.',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(
                15,
                color: colors.subTextColor,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            SizedBox(height: context.heightByContext(28)),
            const SettingsTileSectionTitle('Помощь'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Онбординг',
                  subtitle: 'Показать знакомство с приложением',
                  icon: Icons.auto_awesome_outlined,
                  showChevron: true,
                  onTap: () => context.router.push(OnboardingRoute(replay: true)),
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
