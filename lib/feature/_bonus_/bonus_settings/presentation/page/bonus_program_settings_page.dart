import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_bonus_/bonus_settings/data/models/bonus_program_settings.dart';
import 'package:clover/feature/_bonus_/bonus_settings/data/repository/bonus_program_repository.dart';
import 'package:clover/feature/_bonus_/bonus_settings/presentation/widget/bonus_program_settings_form.dart';
import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BonusProgramSettingsPage extends StatefulWidget {
  const BonusProgramSettingsPage({super.key});

  @override
  State<BonusProgramSettingsPage> createState() => _BonusProgramSettingsPageState();
}

class _BonusProgramSettingsPageState extends State<BonusProgramSettingsPage> {
  late BonusProgramSettings _settings;
  late final BonusProgramStatus _initialStatus;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initialStatus = sl<ProfileCubit>().state.maybeMap(
          loaded: (s) => s.profile.bonusProgramStatus,
          orElse: () => BonusProgramStatus.inactive,
        );
    _settings = BonusProgramSettings.fromStatus(_initialStatus);
  }

  void _onSettingsChanged(BonusProgramSettings value) {
    setState(() => _settings = value);
  }

  Future<void> _save() async {
    if (_settings.status == _initialStatus) {
      await context.router.maybePop();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final saved = await sl<BonusProgramRepository>().updateMyProgramStatus(_settings.status);
      if (!mounted) return;

      sl<ProfileCubit>().patchBonusProgramStatus(saved);

      AppSnackBar.show(context, message: 'Настройки сохранены', kind: AppSnackBarKind.success);
      await context.router.maybePop(true);
    } on BonusProgramException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: e.message, kind: AppSnackBarKind.error);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _settings.status != _initialStatus;
    final canSave = hasChanges && !_isSubmitting;

    return SettingsScreenShell(
      title: 'Бонусы',
      extraButtons: [
        if (canSave || _isSubmitting)
          FunctionalButtonItem(
            icon: Icons.check_rounded,
            label: 'Сохранить',
            keepWhenCollapsed: true,
            customColor: AppColors.primary,
            iconColor: Colors.white,
            textColor: Colors.white,
            isLoading: _isSubmitting,
            onTap: _save,
          ),
      ],
      body: BonusProgramSettingsForm(
        settings: _settings,
        enabled: !_isSubmitting,
        onSettingsChanged: _onSettingsChanged,
      ),
    );
  }
}
