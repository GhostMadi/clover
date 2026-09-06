import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Настройки сервиса «Посещаемость»: ярлыки профиля и переходы в сервис.
@RoutePage()
class SettingsAttendancePage extends StatefulWidget {
  const SettingsAttendancePage({super.key});

  @override
  State<SettingsAttendancePage> createState() => _SettingsAttendancePageState();
}

class _SettingsAttendancePageState extends State<SettingsAttendancePage> {
  late final ProfileAttendanceAdminShortcutStore _adminShortcutStore;
  late final AttendanceContextStore _attendanceStore;
  bool _loading = true;
  bool _isAdmin = false;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _adminShortcutStore = sl<ProfileAttendanceAdminShortcutStore>();
    _attendanceStore = sl<AttendanceContextStore>();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await _attendanceStore.hydrate(uid, force: true);
    await _adminShortcutStore.load(uid);
    final snap = _attendanceStore.snapshot.value;
    if (mounted) {
      setState(() {
        _isAdmin = snap?.isAdmin ?? false;
        _isWorker = snap?.showProfileWorkerButton ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _setAdminShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _adminShortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = attendanceServiceAccent(context.colors);

    return SettingsScreenShell(
      title: 'Посещаемость',
      service: kAttendanceService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAdmin) ...[
              const SettingsTileSectionTitle('Профиль'),
              AppTileGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppSwitchRow(
                      title: 'Управление посещаемостью в профиле',
                      subtitle: 'Быстрый переход к компаниям и настройкам',
                      value: _adminShortcutStore.visible.value,
                      enabled: !_loading,
                      onChanged: _loading ? null : _setAdminShortcut,
                      service: kAttendanceService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            const SettingsTileSectionTitle('Сервис'),
            AppTileGroup(
              children: [
                if (_isAdmin)
                  AppTile(
                    title: 'Управление',
                    subtitle: 'Компании, работники, правила',
                    icon: AppIcons.schedule.icon,
                    iconColor: accent.icon,
                    iconBackgroundColor: accent.soft,
                    showChevron: true,
                    onTap: () => context.router.push(const AttendanceHubRoute()),
                  ),
                if (_isWorker)
                  AppTile(
                    title: 'Моя посещаемость',
                    subtitle: 'Отметки и смены',
                    icon: AppIcons.accessTime.icon,
                    iconColor: accent.icon,
                    iconBackgroundColor: accent.soft,
                    showChevron: true,
                    onTap: () => context.router.push(const AttendanceWorkerHubRoute()),
                  ),
                if (!_isAdmin && !_isWorker)
                  AppTile(
                    title: 'Открыть сервис',
                    subtitle: _loading ? 'Загрузка…' : 'Нет активного участия — можно создать компанию',
                    icon: AppIcons.schedule.icon,
                    iconColor: accent.icon,
                    iconBackgroundColor: accent.soft,
                    showChevron: true,
                    onTap: () => context.router.push(const AttendanceHubRoute()),
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
