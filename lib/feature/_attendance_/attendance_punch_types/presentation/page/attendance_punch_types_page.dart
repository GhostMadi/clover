import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_punch_types/presentation/widget/attendance_punch_add_sheet.dart';
import 'package:clover/feature/_attendance_/attendance_punch_types/presentation/widget/attendance_punch_custom_row.dart';
import 'package:clover/feature/_attendance_/attendance_punch_types/presentation/widget/attendance_punch_system_block.dart';
import 'package:clover/feature/_attendance_/attendance_workplace_settings/presentation/cubit/attendance_workplace_settings_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_settings_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@RoutePage()
class AttendancePunchTypesPage extends StatefulWidget {
  const AttendancePunchTypesPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendancePunchTypesPage> createState() => _AttendancePunchTypesPageState();
}

class _AttendancePunchTypesPageState extends State<AttendancePunchTypesPage> {
  late final AttendanceWorkplaceSettingsCubit _cubit;
  late bool _clockInEnabled;
  late bool _clockOutEnabled;
  late AttendanceDayTime? _clockInTime;
  late AttendanceDayTime? _clockOutTime;
  late List<AttendanceCustomPunchConfig> _customPunches;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceWorkplaceSettingsCubit>()..bind(widget.workplaceId);
    final w = _cubit.state is AttendanceWorkplaceSettingsReady
        ? (_cubit.state as AttendanceWorkplaceSettingsReady).workplace
        : null;
    _clockInEnabled = w?.clockInEnabled ?? true;
    _clockOutEnabled = w?.clockOutEnabled ?? true;
    _clockInTime = w?.clockInScheduledTime;
    _clockOutTime = w?.clockOutScheduledTime;
    _customPunches = List.of(w?.customPunches ?? const []);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _canSave => _clockInEnabled || _clockOutEnabled;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await _cubit.updatePunchConfig(
        clockInEnabled: _clockInEnabled,
        clockOutEnabled: _clockOutEnabled,
        clockInScheduledTime: _clockInTime,
        clockOutScheduledTime: _clockOutTime,
        clearClockInScheduledTime: _clockInTime == null,
        clearClockOutScheduledTime: _clockOutTime == null,
        customPunches: _customPunches,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? 'Сохранено локально' : 'Сохранено',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCustomPunch() async {
    HapticFeedback.selectionClick();
    final created = await AttendancePunchAddSheet.show(context, existing: _customPunches);
    if (created == null || !mounted) return;
    setState(() => _customPunches.add(created));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AttendanceScreenShell(
      title: 'Отметки',
      showSave: true,
      canSave: _canSave && !_saving,
      isSaving: _saving,
      onSaveTap: _save,
      showAdd: true,
      onAddTap: _addCustomPunch,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
        children: [
          AttendanceSettingsSurface(
            title: 'Смена',
            children: [
              AttendancePunchSystemBlock(
                title: AttendanceSystemPunchCode.clockIn.labelRu,
                enabled: _clockInEnabled,
                scheduledTime: _clockInTime,
                onEnabledChanged: (v) => setState(() {
                  _clockInEnabled = v;
                  if (!v) _clockInTime = null;
                }),
                onScheduledTimeChanged: (t) => setState(() => _clockInTime = t),
              ),
              Divider(height: 1, color: colors.divider),
              AttendancePunchSystemBlock(
                title: AttendanceSystemPunchCode.clockOut.labelRu,
                enabled: _clockOutEnabled,
                scheduledTime: _clockOutTime,
                onEnabledChanged: (v) => setState(() {
                  _clockOutEnabled = v;
                  if (!v) _clockOutTime = null;
                }),
                onScheduledTimeChanged: (t) => setState(() => _clockOutTime = t),
              ),
            ],
          ),
          if (!_canSave) ...[
            const SizedBox(height: 10),
            Text(
              'Включите «Пришёл» или «Ушёл»',
              style: AppTextStyle.base(13, color: colors.destructive, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Свои',
            style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_customPunches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Нет своих отметок. «+» сверху.',
                style: AppTextStyle.base(14, color: colors.subTextColor),
              ),
            )
          else
            AttendanceSettingsSurface(
              children: [
                for (var i = 0; i < _customPunches.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.divider),
                  AttendancePunchCustomRow(
                    config: _customPunches[i],
                    onScheduledTimeChanged: (t) => setState(
                      () => _customPunches[i] = _customPunches[i].copyWith(
                        scheduledTime: t,
                        clearScheduledTime: t == null,
                      ),
                    ),
                    onDelete: () => setState(() => _customPunches.removeAt(i)),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
