import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_block.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_duty_today_banner.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendancePunchPage extends StatelessWidget {
  const AttendancePunchPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    final store = sl<AttendanceContextStore>();

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final workplace = snap?.workplaceById(workplaceId);
        final membership = snap?.membershipByWorkplace(workplaceId);
        final colors = context.colors;
        final workerId = membership?.profileId ?? store.selfWorkerId();

        if (workplace == null || membership == null || snap == null) {
          return AttendanceScreenShell(
            title: 'Отметка',
            body: Center(child: Text('Компания не найдена', style: AppTextStyle.base(15, color: colors.subTextColor))),
          );
        }

        final inZone = store.isRemote ? workplace.hasGeofenceCenter : snap.mockInGeofence;
        final gpsOn = store.isRemote ? true : snap.mockGpsEnabled;
        final primaryType = workplace.resolvePrimaryPunchType(shiftOpen: membership.shiftOpen);
        final customTypes = workplace.customPunchTypes;
        final blockReason = _resolveBlock(
          needsAck: membership.needsAck,
          gpsOn: gpsOn,
          inZone: inZone,
          primaryType: primaryType,
        );
        final canPunch = blockReason == null;
        final history = snap.punchHistoryFor(workplaceId: workplaceId, workerId: workerId, includeCancelled: true);

        return AttendanceScreenShell(
          title: workplace.name,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GeofenceStatus(inZone: inZone, gpsOn: gpsOn, radiusM: workplace.geofenceRadiusM),
                if (workplace.dutyRoster.isConfigured) ...[
                  const SizedBox(height: 12),
                  AttendanceDutyTodayBanner(
                    roster: workplace.dutyRoster,
                    selfWorkerId: workerId,
                  ),
                ],
                if (blockReason != null) ...[
                  const SizedBox(height: 12),
                  _BlockReasonCard(
                    reason: blockReason,
                    configVersion: membership.configVersion,
                    workplaceId: workplaceId,
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
                    onTap: canPunch ? () => _punch(context, store, primaryType) : () => _showBlockSheet(context, blockReason),
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
                    onTap: () => _showCustom(context, store, customTypes, blockReason: blockReason),
                  ),
                ],
                if (history.any((e) => !e.cancelled)) ...[
                  const SizedBox(height: 12),
                  AppOutlinedButton(
                    text: 'Отменить последнюю отметку',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: () => _showCancel(context, store),
                  ),
                ],
                if (!store.isRemote) ...[
                  const SizedBox(height: 16),
                  AppOutlinedButton(
                    text: inZone ? 'Симулировать «вне зоны»' : 'Симулировать «в зоне»',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: store.toggleMockGeofence,
                  ),
                  AppOutlinedButton(
                    text: gpsOn ? 'Симулировать GPS выкл.' : 'Симулировать GPS вкл.',
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: store.toggleMockGps,
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
  }) {
    if (needsAck) return AttendancePunchBlockReason.needsAck;
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

  void _punch(BuildContext context, AttendanceContextStore store, AttendancePunchType type) {
    store.punch(workplaceId: workplaceId, type: type);
    AppSnackBar.show(context, message: '${type.labelRu} — сохранено', kind: AppSnackBarKind.success);
    context.router.maybePop();
  }

  Future<void> _showCancel(BuildContext context, AttendanceContextStore store) {
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
            store.cancelLastPunch(
              workplaceId: workplaceId,
              comment: controller.text,
            );
            Navigator.of(context).pop();
            AppSnackBar.show(
              context,
              message: 'Отметка отменена',
              kind: AppSnackBarKind.success,
            );
          },
        ),
      ],
    ).whenComplete(
      () => Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose),
    );
  }

  Future<void> _showCustom(
    BuildContext context,
    AttendanceContextStore store,
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
                _punch(context, store, t);
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
  const _GeofenceStatus({required this.inZone, required this.gpsOn, required this.radiusM});

  final bool inZone;
  final bool gpsOn;
  final int radiusM;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ok = inZone && gpsOn;
    final bg = ok ? colors.functionalSoftBlue : colors.functionalSoftRed.withValues(alpha: 0.25);
    final fg = ok ? colors.functionalSoftBlueIcon : colors.destructive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(ok ? AppIcons.myLocation.icon : AppIcons.locationOn.icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              !gpsOn
                  ? 'GPS выключен'
                  : inZone
                      ? 'Вы в зоне ($radiusM м)'
                      : 'Вы вне зоны',
              style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
