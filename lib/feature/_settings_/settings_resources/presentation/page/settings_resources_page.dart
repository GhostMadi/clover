import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_profile_/profile_page/data/profile_resources_shortcut_store.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Акцент сервиса «Ресурсы» — сиреневый soft + фиолетовые иконки.
@RoutePage()
class SettingsResourcesPage extends StatefulWidget {
  const SettingsResourcesPage({super.key});

  @override
  State<SettingsResourcesPage> createState() => _SettingsResourcesPageState();
}

class _SettingsResourcesPageState extends State<SettingsResourcesPage> {
  late final ProfileResourcesShortcutStore _shortcutStore;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _shortcutStore = sl<ProfileResourcesShortcutStore>();
    _loadShortcut();
  }

  Future<void> _loadShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await _shortcutStore.load(uid);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _shortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

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
            const SettingsTileSectionTitle('Профиль'),
            AppTileGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSwitchRow(
                    title: 'Кнопка «Ресурсы» в профиле',
                    subtitle: 'Быстрый переход к справочникам под кнопкой «Редактировать»',
                    value: _shortcutStore.visible.value,
                    enabled: !_loading,
                    onChanged: _loading ? null : _setShortcut,
                    service: kResourcesService,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Справочники'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Местоположения',
                  subtitle: 'Адреса, точки на карте, зоны доставки',
                  icon: AppIcons.locationOn.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(const LocationRoute()),
                ),
                AppTile(
                  title: 'Фильтры',
                  subtitle: 'Категории и значения для фильтрации',
                  icon: AppIcons.tune.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
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
