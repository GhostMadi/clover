import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_bonus_/bonus_settings/data/models/bonus_program_settings.dart';
import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';

class BonusProgramSettingsForm extends StatelessWidget {
  const BonusProgramSettingsForm({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.enabled = true,
  });

  final BonusProgramSettings settings;
  final ValueChanged<BonusProgramSettings> onSettingsChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSwitchRow(
            title: 'Бонусная программа',
            subtitle: 'Включить начисление и списание бонусов у клиентов',
            value: settings.isEnabled,
            enabled: enabled,
            onChanged: enabled
                ? (value) => onSettingsChanged(
                      settings.copyWith(
                        status: value ? BonusProgramStatus.active : BonusProgramStatus.inactive,
                      ),
                    )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Доля оплаты бонусами настраивается отдельно для каждой услуги при её создании или редактировании.',
            style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
