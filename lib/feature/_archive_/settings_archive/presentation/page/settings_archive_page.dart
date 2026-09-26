import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsArchivePage extends StatelessWidget {
  const SettingsArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: context.l10n.archive_hub_title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsTileSectionTitle(context.l10n.archive_content),
            AppTileGroup(
              children: [
                AppTile(
                  title: context.l10n.common_publications,
                  subtitle: context.l10n.archive_posts_events_subtitle,
                  icon: AppIcons.gridView.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const PostArchiveRoute()),
                ),
                AppTile(
                  title: context.l10n.cluster_tab,
                  subtitle: context.l10n.archive_clusters_subtitle,
                  icon: AppIcons.collectionsFilled.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const ClusterArchiveRoute()),
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
