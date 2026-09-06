import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/attendance_workplace_settings/presentation/cubit/attendance_workplace_settings_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_time_picker_field.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AttendanceScreenShell(
      title: 'Типы отметок',
      showSave: true,
      canSave: _canSave,
      onSaveTap: _save,
      showAdd: true,
      onAddTap: _addCustomPunch,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
        children: [
          Text(
            'У каждого типа можно задать, когда работник должен отметиться — '
            'например «Пришёл» в 09:00 или «Обед» в 13:00.',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Приход и уход',
            children: [
              _SystemPunchBlock(
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
              _SystemPunchBlock(
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
              'Включите хотя бы «Пришёл» или «Ушёл»',
              style: AppTextStyle.base(13, color: colors.destructive, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Свои отметки',
            style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '«Обед», «Перерыв», «Выезд на точку» — с опциональным временем в расписании.',
            style: AppTextStyle.base(13, color: colors.subTextColor),
          ),
          const SizedBox(height: 10),
          if (_customPunches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Пока нет своих отметок. Нажмите + чтобы добавить.',
                textAlign: TextAlign.center,
                style: AppTextStyle.base(14, color: colors.subTextColor),
              ),
            )
          else
            _SectionCard(
              children: [
                for (var i = 0; i < _customPunches.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.divider),
                  _CustomPunchRow(
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

  Future<void> _save() async {
    if (!_canSave) return;

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
        message: result == AttendancePersistResult.queued
            ? 'Сохранено локально, синхронизируется'
            : 'Сохранено',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _addCustomPunch() async {
    final labelController = TextEditingController();
    var scheduleEnabled = false;
    AttendanceDayTime? scheduledTime;

    await AttendanceBottomSheet.show(
      context: context,
      title: 'Своя отметка',
      content: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AttendanceField(
                labelText: 'Название',
                hintText: 'Обед',
                controller: labelController,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              AppSwitchRow(
                title: 'Указать время',
                subtitle: 'Когда работник должен отметиться.',
                value: scheduleEnabled,
                service: kAttendanceService,
                onChanged: (v) => setSheetState(() {
                  scheduleEnabled = v;
                  if (!v) {
                    scheduledTime = null;
                  } else {
                    scheduledTime ??= const AttendanceDayTime(hour: 12, minute: 0);
                  }
                }),
              ),
              if (scheduleEnabled) ...[
                const SizedBox(height: 12),
                AttendanceTimePickerField(
                  enabled: true,
                  time: scheduledTime,
                  onChanged: (t) => setSheetState(() => scheduledTime = t),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Добавить',
          isExpanded: true,
          onTap: () {
            final label = labelController.text.trim();
            if (label.isEmpty) return;
            if (_customPunches.any((e) => e.label.toLowerCase() == label.toLowerCase())) {
              AppSnackBar.show(context, message: 'Уже есть', kind: AppSnackBarKind.info);
              return;
            }
            setState(
              () => _customPunches.add(
                AttendanceCustomPunchConfig(
                  label: label,
                  scheduledTime: scheduleEnabled ? scheduledTime : null,
                ),
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    Future<void>.delayed(const Duration(milliseconds: 400), labelController.dispose);
  }
}

class _SystemPunchBlock extends StatelessWidget {
  const _SystemPunchBlock({
    required this.title,
    required this.enabled,
    required this.scheduledTime,
    required this.onEnabledChanged,
    required this.onScheduledTimeChanged,
  });

  final String title;
  final bool enabled;
  final AttendanceDayTime? scheduledTime;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AttendanceDayTime?> onScheduledTimeChanged;

  @override
  Widget build(BuildContext context) {
    final scheduleOn = scheduledTime != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              AppSwitch(value: enabled, service: kAttendanceService, onChanged: onEnabledChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ожидается в',
                    style: AppTextStyle.base(14, color: context.colors.subTextColor),
                  ),
                ),
                AppSwitch(
                  value: scheduleOn,
                  service: kAttendanceService,
                  onChanged: (v) {
                    if (v) {
                      onScheduledTimeChanged(scheduledTime ?? const AttendanceDayTime(hour: 9, minute: 0));
                    } else {
                      onScheduledTimeChanged(null);
                    }
                  },
                ),
              ],
            ),
            if (scheduleOn) ...[
              const SizedBox(height: 10),
              AttendanceTimePickerField(
                enabled: true,
                time: scheduledTime,
                onChanged: onScheduledTimeChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CustomPunchRow extends StatelessWidget {
  const _CustomPunchRow({
    required this.config,
    required this.onScheduledTimeChanged,
    required this.onDelete,
  });

  final AttendanceCustomPunchConfig config;
  final ValueChanged<AttendanceDayTime?> onScheduledTimeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheduleOn = config.hasScheduledTime;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.label,
                      style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w600),
                    ),
                    if (scheduleOn)
                      Text(
                        'в ${config.scheduledTime!.labelRu}',
                        style: AppTextStyle.base(13, color: colors.functionalSoftBlueIcon, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.delete.icon, color: colors.destructive),
                onPressed: onDelete,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ожидается в',
                  style: AppTextStyle.base(14, color: colors.subTextColor),
                ),
              ),
              AppSwitch(
                value: scheduleOn,
                service: kAttendanceService,
                onChanged: (v) {
                  if (v) {
                    onScheduledTimeChanged(config.scheduledTime ?? const AttendanceDayTime(hour: 12, minute: 0));
                  } else {
                    onScheduledTimeChanged(null);
                  }
                },
              ),
            ],
          ),
          if (scheduleOn) ...[
            const SizedBox(height: 10),
            AttendanceTimePickerField(
              enabled: true,
              time: config.scheduledTime,
              onChanged: onScheduledTimeChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text(title!, style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w700)),
            ),
          ...children,
        ],
      ),
    );
  }
}
