import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/attendance_punch/presentation/cubit/attendance_punch_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_block.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_duty_today_banner.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendancePunchPage extends StatefulWidget {
  const AttendancePunchPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendancePunchPage> createState() => _AttendancePunchPageState();
}

class _AttendancePunchPageState extends State<AttendancePunchPage> {
  late final AttendancePunchCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendancePunchCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendancePunchCubit, AttendancePunchState>(
      bloc: _cubit,
      builder: (context, state) {
        final colors = context.colors;

        if (state is! AttendancePunchReady) {
          return AttendanceScreenShell(
            title: 'Отметка',
            body: Center(
              child: Text('Компания не найдена', style: AppTextStyle.base(15, color: colors.subTextColor)),
            ),
          );
        }

        final workplace = state.workplace;
        final membership = state.membership;
        final workerId = state.workerId;
        final inZone = state.inZone;
        final gpsOn = state.gpsOn;
        final locating = state.locating;
        final primaryType = workplace.resolvePrimaryPunchType(shiftOpen: membership.shiftOpen);
        final customTypes = workplace.customPunchTypes;
        final blockReason = locating
            ? null
            : _resolveBlock(
                needsAck: membership.needsAck,
                gpsOn: gpsOn,
                inZone: inZone,
                primaryType: primaryType,
                dutyOnlyPunch: workplace.dutyOnlyPunch,
                onDutyToday: workplace.dutyRoster.isConfigured
                    ? workplace.dutyRoster.onDutyFor(DateTime.now()).contains(workerId)
                    : true,
              );
        final canPunch = !locating && blockReason == null;
        final history = state.history;

        return AttendanceScreenShell(
          title: workplace.name,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GeofenceStatus(
                  inZone: inZone,
                  gpsOn: gpsOn,
                  radiusM: workplace.geofenceRadiusM,
                  locating: locating,
                  onRefresh: () => _cubit.refreshLocation(),
                ),
                if (workplace.dutyRoster.isConfigured) ...[
                  const SizedBox(height: 12),
                  AttendanceDutyTodayBanner(
                    roster: workplace.dutyRoster,
                    selfWorkerId: workerId,
                    displayNames: state.snapshot.profileDisplayNames,
                    dutyOnlyPunch: workplace.dutyOnlyPunch,
                  ),
                ],
                if (blockReason != null) ...[
                  const SizedBox(height: 12),
                  _BlockReasonCard(
                    reason: blockReason,
                    configVersion: membership.configVersion,
                    workplaceId: widget.workplaceId,
                  ),
                ],
                const SizedBox(height: 16),
                _EnabledTypesHint(workplace: workplace),
                const SizedBox(height: 20),
                if (primaryType != null)
                  AttendancePrimaryButton(
                    text: primaryType.labelRu.toUpperCase(),
                    isExpanded: true,
                    interactive: canPunch,
                    onTap: canPunch
                        ? () => _punch(primaryType)
                        : blockReason != null
                            ? () => _showBlockSheet(context, blockReason)
                            : () {},
                  )
                else
                  Builder(
                    builder: (context) {
                      final yellow = attendanceYellowAccent(colors);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: yellow.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: yellow.icon.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'Админ не включил «Пришёл» и «Ушёл». Только свои отметки ниже.',
                          style: AppTextStyle.base(14, color: colors.textColor),
                        ),
                      );
                    },
                  ),
                if (customTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppOutlinedButton(
                    text: 'Свои отметки',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: () => _showCustom(context, customTypes, blockReason: blockReason),
                  ),
                ],
                if (history.any((e) => !e.cancelled)) ...[
                  const SizedBox(height: 12),
                  AppOutlinedButton(
                    text: 'Отменить последнюю отметку',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: () => _showCancel(context),
                  ),
                ],
                if (!state.isRemote) ...[
                  const SizedBox(height: 16),
                  AppOutlinedButton(
                    text: inZone ? 'Симулировать «вне зоны»' : 'Симулировать «в зоне»',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: _cubit.toggleMockGeofence,
                  ),
                  AppOutlinedButton(
                    text: gpsOn ? 'Симулировать GPS выкл.' : 'Симулировать GPS вкл.',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: _cubit.toggleMockGps,
                  ),
                ],
                const SizedBox(height: 24),
                Text('История отметок', style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Text('Пока нет отметок', style: AppTextStyle.base(14, color: colors.subTextColor))
                else
                  for (final record in history.take(12)) _HistoryRow(record: record),
              ],
            ),
          ),
        );
      },
    );
  }

  AttendancePunchBlockReason? _resolveBlock({
    required bool needsAck,
    required bool gpsOn,
    required bool inZone,
    required AttendancePunchType? primaryType,
    required bool dutyOnlyPunch,
    required bool onDutyToday,
  }) {
    if (needsAck) return AttendancePunchBlockReason.needsAck;
    if (dutyOnlyPunch && !onDutyToday) return AttendancePunchBlockReason.notOnDuty;
    if (!gpsOn) return AttendancePunchBlockReason.gpsDisabled;
    if (!inZone) return AttendancePunchBlockReason.outsideGeofence;
    if (primaryType == null) return AttendancePunchBlockReason.noPrimaryPunchType;
    return null;
  }

  void _showBlockSheet(BuildContext context, AttendancePunchBlockReason reason) {
    AttendanceBottomSheet.show(
      context: context,
      title: reason.titleRu,
      content: Text(reason.detailRu, style: AppTextStyle.base(15, color: context.colors.subTextColor, height: 1.4)),
      actions: [
        AttendancePrimaryButton(
          text: 'Понятно',
          isExpanded: true,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _punch(AttendancePunchType type) async {
    final ok = await _cubit.punch(type);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(context, message: '${type.labelRu} — сохранено', kind: AppSnackBarKind.success);
      context.router.maybePop();
    } else {
      final msg = _cubit.lastPunchError?.userMessage ?? 'Не удалось сохранить отметку';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _showCancel(BuildContext context) {
    final controller = TextEditingController();
    return AttendanceBottomSheet.show(
      context: context,
      title: 'Отменить отметку',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Комментарий необязателен — например, отметили по ошибке.',
            style: AppTextStyle.base(14, color: context.colors.subTextColor),
          ),
          const SizedBox(height: 12),
          AttendanceField(controller: controller, labelText: 'Комментарий (необяз.)'),
        ],
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Отменить отметку',
          isExpanded: true,
          onTap: () {
            _cubit.cancelLastPunch(comment: controller.text);
            Navigator.of(context).pop();
            AppSnackBar.show(
              context,
              message: 'Отметка отменена',
              kind: AppSnackBarKind.success,
            );
          },
        ),
        AppOutlinedButton(
          text: 'Запросить исправление',
          isExpanded: true,
          service: kAttendanceService,
          onTap: () async {
            final last = _cubit.state is AttendancePunchReady
                ? (_cubit.state as AttendancePunchReady)
                    .history
                    .where((e) => !e.cancelled)
                    .fold<AttendancePunchRecord?>(null, (prev, e) => e)
                : null;
            if (last == null) {
              AppSnackBar.show(context, message: 'Нет отметки для исправления', kind: AppSnackBarKind.error);
              return;
            }
            try {
              final ok = await _cubit.requestPunchCorrection(
                punchId: last.id,
                note: controller.text.trim().isEmpty ? null : controller.text.trim(),
              );
              if (!context.mounted) return;
              if (!ok) {
                AppSnackBar.show(
                  context,
                  message: _cubit.lastPunchError?.userMessage ?? 'Не удалось отправить запрос',
                  kind: AppSnackBarKind.error,
                );
                return;
              }
              Navigator.of(context).pop();
              AppSnackBar.show(
                context,
                message: 'Запрос на исправление отправлен',
                kind: AppSnackBarKind.success,
              );
            } catch (e) {
              if (!context.mounted) return;
              final msg = e is AttendanceException ? e.userMessage : 'Не удалось отправить запрос';
              AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
            }
          },
        ),
      ],
    ).whenComplete(
      () => Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose),
    );
  }

  Future<void> _showCustom(
    BuildContext context,
    List<AttendancePunchType> types, {
    required AttendancePunchBlockReason? blockReason,
  }) {
    return AttendanceBottomSheet.show(
      context: context,
      title: 'Свои отметки',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in types)
            AppTile(
              title: t.labelRu,
              onTap: () {
                Navigator.of(context).pop();
                if (blockReason != null) {
                  _showBlockSheet(context, blockReason);
                  return;
                }
                _punch(t);
              },
            ),
        ],
      ),
    );
  }
}

class _BlockReasonCard extends StatelessWidget {
  const _BlockReasonCard({
    required this.reason,
    required this.configVersion,
    required this.workplaceId,
  });

  final AttendancePunchBlockReason reason;
  final int configVersion;
  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    final yellow = attendanceYellowAccent(context.colors);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: yellow.icon.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reason.titleRu, style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            reason == AttendancePunchBlockReason.needsAck
                ? 'Примите правила v$configVersion карточкой в чате компании.'
                : reason.detailRu,
            style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
          ),
          if (reason == AttendancePunchBlockReason.needsAck) ...[
            const SizedBox(height: 12),
            AppOutlinedButton(
              text: 'Открыть чат',
              isExpanded: true,
              service: kAttendanceService,
              height: 44,
              onTap: () => openAttendanceCompanyChat(context, workplaceId),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final AttendancePunchRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.formattedAt} · ${record.type.labelRu}${record.cancelled ? ' · отменено' : ''}',
                  style: AppTextStyle.base(
                    14,
                    color: record.cancelled ? colors.subTextColor : colors.textColor,
                  ).copyWith(
                    decoration: record.cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (record.cancelComment != null)
                  Text(record.cancelComment!, style: AppTextStyle.base(12, color: colors.subTextColor)),
              ],
            ),
          ),
          if (!record.cancelled)
            Icon(AppIcons.checkCircleOutline.icon, size: 18, color: accent.icon),
        ],
      ),
    );
  }
}

class _EnabledTypesHint extends StatelessWidget {
  const _EnabledTypesHint({required this.workplace});

  final AttendanceWorkplace workplace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = <String>[];
    if (workplace.clockInEnabled) {
      final t = workplace.clockInScheduledTime;
      parts.add(t != null ? 'Пришёл ${t.labelRu}' : 'Пришёл');
    }
    if (workplace.clockOutEnabled) {
      final t = workplace.clockOutScheduledTime;
      parts.add(t != null ? 'Ушёл ${t.labelRu}' : 'Ушёл');
    }
    for (final c in workplace.customPunches) {
      parts.add(c.hasScheduledTime ? '${c.label} ${c.scheduledTime!.labelRu}' : c.label);
    }

    return Text(
      parts.isEmpty ? 'Типы не настроены' : 'Включено: ${parts.join(' · ')}',
      style: AppTextStyle.base(13, color: colors.subTextColor),
    );
  }
}

class _GeofenceStatus extends StatelessWidget {
  const _GeofenceStatus({
    required this.inZone,
    required this.gpsOn,
    required this.radiusM,
    this.locating = false,
    this.onRefresh,
  });

  final bool inZone;
  final bool gpsOn;
  final int radiusM;
  final bool locating;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ok = inZone && gpsOn;
    final bg = locating
        ? colors.surfaceMuted
        : ok
            ? colors.functionalSoftBlue
            : colors.functionalSoftRed.withValues(alpha: 0.25);
    final fg = locating
        ? colors.iconMuted
        : ok
            ? colors.functionalSoftBlueIcon
            : colors.destructive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          if (locating)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.iconMuted),
            )
          else
            Icon(ok ? AppIcons.myLocation.icon : AppIcons.locationOn.icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              locating
                  ? 'Определяем местоположение…'
                  : !gpsOn
                      ? 'GPS недоступен'
                      : inZone
                          ? 'Вы в зоне ($radiusM м)'
                          : 'Вы вне зоны',
              style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w600),
            ),
          ),
          if (onRefresh != null && !locating)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(AppIcons.myLocation.icon, color: colors.iconMuted, size: 20),
              tooltip: 'Обновить GPS',
            ),
        ],
      ),
    );
  }
}
