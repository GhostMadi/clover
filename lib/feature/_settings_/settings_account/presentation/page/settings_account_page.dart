import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/core/theme/app_theme_cubit.dart';
import 'package:clover/core/theme/app_theme_mode.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart';
import 'package:clover/feature/_profile_/profile_page/data/profile_booking_shortcut_store.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _SettingsAccountLanguage {
  ru('ru', 'Русский'),
  en('en', 'English'),
  kk('kk', 'Қазақша');

  const _SettingsAccountLanguage(this.code, this.label);

  final String code;
  final String label;
}

@RoutePage()
class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  _SettingsAccountLanguage _language = _SettingsAccountLanguage.ru;
  bool _isLoggingOut = false;
  late final ProfileBookingShortcutStore _bookingShortcutStore;
  late final ProfileAttendanceAdminShortcutStore _attendanceAdminShortcutStore;
  late final AttendanceContextStore _attendanceStore;
  bool _bookingShortcutLoading = true;
  bool _attendanceAdminShortcutLoading = true;
  bool _attendanceAdminEligible = false;
  bool _hasPasswordLoading = true;
  bool? _hasPassword;

  @override
  void initState() {
    super.initState();
    _bookingShortcutStore = sl<ProfileBookingShortcutStore>();
    _attendanceAdminShortcutStore = sl<ProfileAttendanceAdminShortcutStore>();
    _attendanceStore = sl<AttendanceContextStore>();
    _loadBookingShortcut();
    _loadAttendanceAdminShortcut();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHasPassword());
  }

  Future<void> _loadBookingShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _bookingShortcutLoading = false);
      return;
    }
    await _bookingShortcutStore.load(uid);
    if (mounted) setState(() => _bookingShortcutLoading = false);
  }

  Future<void> _loadHasPassword() async {
    setState(() => _hasPasswordLoading = true);
    try {
      final has = await context.read<AuthCubit>().currentUserHasPassword();
      if (!mounted) return;
      setState(() {
        _hasPassword = has;
        _hasPasswordLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasPassword = null;
        _hasPasswordLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceAdminShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _attendanceAdminShortcutLoading = false);
      return;
    }
    await _attendanceStore.hydrate(uid);
    await _attendanceAdminShortcutStore.load(uid);
    if (mounted) {
      setState(() {
        _attendanceAdminEligible = _attendanceStore.snapshot.value?.isAdmin ?? false;
        _attendanceAdminShortcutLoading = false;
      });
    }
  }

  Future<void> _setAttendanceAdminShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _attendanceAdminShortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

  Future<void> _setBookingShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _bookingShortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

  Future<void> _pickLanguage() async {
    final picked = await _showOptionSheet<_SettingsAccountLanguage>(
      title: 'Язык',
      options: _SettingsAccountLanguage.values,
      selected: _language,
      label: (option) => option.label,
    );
    if (picked == null || !mounted) return;
    setState(() => _language = picked);
  }

  Future<void> _pickTheme() async {
    final cubit = context.read<AppThemeCubit>();
    final picked = await _showOptionSheet<AppThemeMode>(
      title: 'Тема',
      options: AppThemeMode.values,
      selected: cubit.state,
      label: (option) => option.labelRu,
    );
    if (picked == null || !mounted) return;
    await cubit.setMode(picked);
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T option) label,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      title: title,
      content: Builder(
        builder: (sheetContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                AppTile(
                  title: label(option),
                  filled: true,
                  selected: option == selected,
                  showChevron: option == selected,
                  trailing: option == selected
                      ? Icon(AppIcons.check.icon, color: context.colors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          );
        },
      ),
    );
  }

  String get _passwordTileTitle {
    if (_hasPassword == true) return 'Сбросить пароль';
    if (_hasPassword == false) return 'Установить пароль';
    return 'Пароль';
  }

  String get _passwordTileSubtitle {
    if (_hasPasswordLoading) return 'Проверяем…';
    if (_hasPassword == true) return 'Код на email → новый пароль';
    if (_hasPassword == false) return 'Задать пароль для входа по email или нику';
    return 'Не удалось проверить статус пароля';
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Выход',
      content: Text(
        'Выйти из аккаунта на этом устройстве?',
        style: TextStyle(color: context.colors.subTextColor, fontSize: 14, height: 1.4),
      ),
      actions: [
        Builder(
          builder: (sheetContext) {
            return Row(
              children: [
                Expanded(
                  child: AppButton(text: 'Отмена', onTap: () => Navigator.of(sheetContext).pop(false)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(text: 'Выйти', onTap: () => Navigator.of(sheetContext).pop(true)),
                ),
              ],
            );
          },
        ),
      ],
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await context.read<AuthCubit>().logout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeCubit>().state;

    return SettingsScreenShell(
      title: 'Аккаунт',
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
                    title: 'Кнопка «Запись» в профиле',
                    subtitle: 'Быстрый переход к «Мои записи» под кнопкой «Редактировать»',
                    value: _bookingShortcutStore.visible.value,
                    enabled: !_bookingShortcutLoading,
                    onChanged: _bookingShortcutLoading ? null : _setBookingShortcut,
                  ),
                ),
                if (_attendanceAdminEligible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppSwitchRow(
                      title: 'Управление посещаемостью в профиле',
                      subtitle: 'Быстрый переход к компаниям и настройкам',
                      value: _attendanceAdminShortcutStore.visible.value,
                      enabled: !_attendanceAdminShortcutLoading,
                      onChanged: _attendanceAdminShortcutLoading ? null : _setAttendanceAdminShortcut,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Общее'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Язык',
                  subtitle: _language.label,
                  icon: AppIcons.language.icon,
                  showChevron: true,
                  onTap: _pickLanguage,
                ),
                AppTile(
                  title: 'Тема',
                  subtitle: themeMode.labelRu,
                  icon: AppIcons.theme.icon,
                  showChevron: true,
                  onTap: _pickTheme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Безопасность'),
            AppTileGroup(
              children: [
                AppTile(
                  title: _passwordTileTitle,
                  subtitle: _passwordTileSubtitle,
                  icon: AppIcons.lock.icon,
                  showChevron: true,
                  enabled: !_hasPasswordLoading && _hasPassword != null,
                  onTap: () async {
                    await context.router.push(const SettingsPasswordRoute());
                    if (mounted) await _loadHasPassword();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Сессия'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Выйти из аккаунта',
                  icon: AppIcons.logout.icon,
                  iconColor: context.colors.destructive,
                  destructive: true,
                  enabled: !_isLoggingOut,
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _confirmLogout,
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
