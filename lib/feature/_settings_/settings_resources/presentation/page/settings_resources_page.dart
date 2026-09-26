import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_resources/presentation/widget/resources_hub_nav_card.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Хаб «Ресурсы»: грид → местоположения / фильтры / гайд.
@RoutePage()
class SettingsResourcesPage extends StatelessWidget {
  const SettingsResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: context.l10n.settings_resources_title,
      service: kResourcesService,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
        children: [
          ResourcesHubNavGrid(
            children: [
              ResourcesHubNavCard(
                title: context.l10n.catalog_locations_title,
                subtitle: context.l10n.settings_resources_addresses,
                icon: AppIcons.locationOn.icon,
                onTap: () => context.router.push(const LocationRoute()),
              ),
              ResourcesHubNavCard(
                title: context.l10n.common_filters,
                subtitle: context.l10n.settings_resources_showcase,
                icon: AppIcons.tune.icon,
                onTap: () => context.router.push(const SettingsFiltersRoute()),
              ),
              ResourcesHubNavCard(
                title: context.l10n.settings_guide_title,
                subtitle: context.l10n.settings_resources_what,
                icon: AppIcons.infoOutline.icon,
                onTap: () => context.router.push(
                  SettingsResourcesGuideRoute(topicKey: 'overview'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
