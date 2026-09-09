import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:clover/feature/_settings_/settings_guide/data/services_guide_catalog.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsGuidePage extends StatelessWidget {
  const SettingsGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SettingsScreenShell(
      title: 'Гайд',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Как пользоваться сервисами Clover: запись, посещаемость и ресурсы.',
              style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 16),
            const SettingsTileSectionTitle('Сервисы'),
            AppTileGroup(
              children: [
                for (final item in ServicesGuideCatalog.all)
                  Builder(
                    builder: (context) {
                      final accent = item.topic.serviceKind != null
                          ? colors.serviceAccent(item.topic.serviceKind!)
                          : null;
                      return AppTile(
                        title: item.cardTitle,
                        subtitle: item.cardSubtitle,
                        icon: item.cardIcon,
                        iconColor: accent?.icon ?? colors.primary,
                        iconBackgroundColor: accent?.soft ?? colors.surfaceSoft,
                        showChevron: true,
                        onTap: () => context.router.push(
                          SettingsGuideTopicRoute(topicKey: item.topic.key),
                        ),
                      );
                    },
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
