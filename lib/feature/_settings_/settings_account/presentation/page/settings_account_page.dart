import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/locale/app_locale.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/core/theme/app_theme_cubit.dart';
import 'package:clover/core/theme/app_theme_mode.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  bool _isLoggingOut = false;
  bool _isHibernating = false;
  bool _isDeleting = false;
  bool _hasPasswordLoading = true;
  bool? _hasPassword;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHasPassword());
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

  Future<void> _pickLanguage() async {
    final cubit = context.read<AppLocaleCubit>();
    final picked = await _showOptionSheet<AppLocale>(
      title: context.l10n.settings_account_language,
      options: AppLocale.values,
      selected: cubit.state,
      label: (option) => option.endonym,
    );
    if (picked == null || !mounted) return;
    await cubit.setLocale(picked);
  }

  Future<void> _pickTheme() async {
    final cubit = context.read<AppThemeCubit>();
    final l10n = context.l10n;
    final picked = await _showOptionSheet<AppThemeMode>(
      title: l10n.settings_account_theme,
      options: AppThemeMode.values,
      selected: cubit.state,
      label: (option) => option.label(l10n),
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
    final l10n = context.l10n;
    if (_hasPassword == true) return l10n.settings_account_reset_password;
    if (_hasPassword == false) return l10n.settings_account_set_password;
    return l10n.common_password;
  }

  String get _passwordTileSubtitle {
    final l10n = context.l10n;
    if (_hasPasswordLoading) return l10n.common_checking;
    if (_hasPassword == true) return l10n.settings_account_password_reset_hint;
    if (_hasPassword == false) return l10n.settings_account_password_set_hint;
    return l10n.settings_account_password_check_failed;
  }

  Future<void> _confirmLogout() async {
    if (_sessionBusy) return;
    final l10n = context.l10n;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: l10n.settings_account_logout_title,
      content: Text(
        l10n.settings_account_logout_confirm,
        style: TextStyle(color: context.colors.subTextColor, fontSize: 14, height: 1.4),
      ),
      actions: [
        Builder(
          builder: (sheetContext) {
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: l10n.common_cancel,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: l10n.common_logout,
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

  bool get _sessionBusy => _isLoggingOut || _isHibernating || _isDeleting;

  Future<void> _confirmHibernate() async {
    if (_sessionBusy) return;
    final l10n = context.l10n;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: l10n.settings_account_hibernate_title,
      content: Text(
        l10n.settings_account_hibernate_body,
        style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
      ),
      actions: [
        Builder(
          builder: (sheetContext) {
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: l10n.common_cancel,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: l10n.settings_account_hibernate_action,
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

    setState(() {
      _isHibernating = true;
      _sessionError = null;
    });
    await context.read<AuthCubit>().hibernateAccount();
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthError) {
      setState(() {
        _sessionError = AuthErrorMessages.messageFor(state.code, context.l10n);
        _isHibernating = false;
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_sessionBusy) return;
    final l10n = context.l10n;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: l10n.settings_account_deactivate_title,
      content: Text(
        l10n.settings_account_deactivate_body,
        style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
      ),
      actions: [
        Builder(
          builder: (sheetContext) {
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: l10n.common_cancel,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: l10n.settings_account_deactivate_action,
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

    setState(() {
      _isDeleting = true;
      _sessionError = null;
    });
    await context.read<AuthCubit>().deleteAccount();
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthError) {
      setState(() {
        _sessionError = AuthErrorMessages.messageFor(
          state.code == AuthErrorCode.unknown
              ? AuthErrorCode.deleteAccountFailed
              : state.code,
          context.l10n,
        );
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeCubit>().state;
    final locale = context.watch<AppLocaleCubit>().state;
    final l10n = context.l10n;

    return SettingsScreenShell(
      title: l10n.settings_account_page_title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsTileSectionTitle(l10n.settings_account_section_general),
            AppTileGroup(
              children: [
                AppTile(
                  title: l10n.settings_account_language,
                  subtitle: locale.endonym,
                  icon: AppIcons.language.icon,
                  showChevron: true,
                  onTap: _pickLanguage,
                ),
                AppTile(
                  title: l10n.settings_account_theme,
                  subtitle: themeMode.label(l10n),
                  icon: AppIcons.theme.icon,
                  showChevron: true,
                  onTap: _pickTheme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SettingsTileSectionTitle(l10n.settings_account_section_security),
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
            SettingsTileSectionTitle(l10n.settings_account_section_session),
            AppTileGroup(
              children: [
                AppTile(
                  title: l10n.settings_account_logout_action,
                  icon: AppIcons.logout.icon,
                  iconColor: context.colors.destructive,
                  destructive: true,
                  enabled: !_sessionBusy,
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _confirmLogout,
                ),
                AppTile(
                  title: l10n.settings_account_hibernate_title,
                  subtitle: l10n.settings_account_hibernate_subtitle,
                  icon: AppIcons.visibilityOff.icon,
                  iconColor: context.colors.subTextColor,
                  enabled: !_sessionBusy,
                  trailing: _isHibernating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _confirmHibernate,
                ),
                AppTile(
                  title: l10n.settings_account_deactivate_tile,
                  subtitle: l10n.settings_account_deactivate_subtitle,
                  icon: AppIcons.delete.icon,
                  iconColor: context.colors.destructive,
                  destructive: true,
                  enabled: !_sessionBusy,
                  trailing: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
            if (_sessionError != null) ...[
              const SizedBox(height: 12),
              Text(
                _sessionError!,
                style: AppTextStyle.base(13, color: context.colors.destructive, height: 1.35),
              ),
            ],
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}
