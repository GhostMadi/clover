import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _SettingsAccountLanguage {
  ru('ru', 'Русский'),
  en('en', 'English'),
  kk('kk', 'Қазақша');

  const _SettingsAccountLanguage(this.code, this.label);

  final String code;
  final String label;
}

enum _SettingsAccountTheme {
  system('system', 'Системная'),
  light('light', 'Светлая'),
  dark('dark', 'Тёмная');

  const _SettingsAccountTheme(this.code, this.label);

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
  _SettingsAccountTheme _theme = _SettingsAccountTheme.system;
  bool _isLoggingOut = false;

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
    final picked = await _showOptionSheet<_SettingsAccountTheme>(
      title: 'Тема',
      options: _SettingsAccountTheme.values,
      selected: _theme,
      label: (option) => option.label,
    );
    if (picked == null || !mounted) return;
    setState(() => _theme = picked);
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
                      ? Icon(AppIcons.check.icon, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Выход',
      content: const Text(
        'Выйти из аккаунта на этом устройстве?',
        style: TextStyle(color: AppColors.subTextColor, fontSize: 14, height: 1.4),
      ),
      actions: [
        Builder(
          builder: (sheetContext) {
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Отмена',
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Выйти',
                    onTap: () => Navigator.of(sheetContext).pop(true),
                  ),
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
    return SettingsScreenShell(
      title: 'Аккаунт',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  subtitle: _theme.label,
                  icon: AppIcons.theme.icon,
                  showChevron: true,
                  onTap: _pickTheme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Сессия'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Выйти из аккаунта',
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.destructive,
                  destructive: true,
                  enabled: !_isLoggingOut,
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.destructive),
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
