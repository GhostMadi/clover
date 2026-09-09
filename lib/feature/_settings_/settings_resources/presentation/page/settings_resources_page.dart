import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:clover/feature/_settings_/settings_resources/data/resources_guide_catalog.dart';
import 'package:flutter/material.dart';

/// Настройки «Ресурсы». Кнопка в профиле — по тегу `resources`, не prefs.
@RoutePage()
class SettingsResourcesPage extends StatelessWidget {
  const SettingsResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(kResourcesService);

    return SettingsScreenShell(
      title: 'Ресурсы',
      service: kResourcesService,
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
                  subtitle: 'Адреса и точки на карте для постов',
                  icon: AppIcons.locationOn.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const LocationRoute()),
                ),
                AppTile(
                  title: 'Фильтры',
                  subtitle: 'Категории витрины профиля',
                  icon: AppIcons.tune.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsFiltersRoute()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SettingsTileSectionTitle('Гайд'),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 420;
                final cards = ResourcesGuideCatalog.all
                    .map(
                      (item) => _ResourcesGuideCard(
                        content: item,
                        accent: accent,
                        onTap: () => context.router.push(
                          SettingsResourcesGuideRoute(topicKey: item.topic.key),
                        ),
                      ),
                    )
                    .toList(growable: false);

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      cards[i],
                    ],
                  ],
                );
              },
            ),
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}

class _ResourcesGuideCard extends StatelessWidget {
  const _ResourcesGuideCard({
    required this.content,
    required this.accent,
    required this.onTap,
  });

  final ResourcesGuideContent content;
  final AppServiceAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSoft),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(content.cardIcon, color: accent.icon, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                content.cardTitle,
                style: AppTextStyle.base(
                  15,
                  color: colors.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content.cardSubtitle,
                style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
