import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_bonus_/bonus_settings/presentation/cubit/bonus_program_settings_cubit.dart';
import 'package:clover/feature/_bonus_/bonus_settings/presentation/widget/bonus_program_settings_form.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BonusProgramSettingsPage extends StatelessWidget {
  const BonusProgramSettingsPage({super.key});

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<BonusProgramSettingsCubit>();
    final cur = cubit.state;
    if (cur is! BonusProgramSettingsReady) return;

    if (cur.draft.status == cur.initial.status) {
      await context.router.maybePop();
      return;
    }

    final ok = await cubit.save();
    if (!context.mounted) return;

    if (ok) {
      AppSnackBar.show(context, message: 'Настройки сохранены', kind: AppSnackBarKind.success);
      await context.router.maybePop(true);
      return;
    }

    String? message;
    if (cubit.state case BonusProgramSettingsReady(:final errorMessage)) {
      message = errorMessage;
    }
    if (message != null && message.isNotEmpty) {
      AppSnackBar.show(context, message: message, kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BonusProgramSettingsCubit>()..init(),
      child: BlocBuilder<BonusProgramSettingsCubit, BonusProgramSettingsState>(
        builder: (context, state) {
          if (state is BonusProgramSettingsInitial) {
            return const SettingsScreenShell(
              title: 'Бонусы',
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is BonusProgramSettingsReady) {
            final initial = state.initial;
            final draft = state.draft;
            final isSaving = state.isSaving;
            return SettingsScreenShell(
              title: 'Бонусы',
              extraButtons: [
                if (draft.status != initial.status || isSaving)
                  FunctionalButtonItem(
                    icon: Icons.check_rounded,
                    label: 'Сохранить',
                    keepWhenCollapsed: true,
                    customColor: AppColors.primary,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    isLoading: isSaving,
                    onTap: () => _save(context),
                  ),
              ],
              body: BonusProgramSettingsForm(
                settings: draft,
                enabled: !isSaving,
                onSettingsChanged: context.read<BonusProgramSettingsCubit>().updateDraft,
              ),
            );
          }
          if (state is BonusProgramSettingsError) {
            return SettingsScreenShell(
              title: 'Бонусы',
              body: Center(child: Text(state.message)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
