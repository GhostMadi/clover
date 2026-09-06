import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_worker/presentation/cubit/attendance_worker_hub_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_duty_today_banner.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceWorkerHubPage extends StatefulWidget {
  const AttendanceWorkerHubPage({super.key});

  @override
  State<AttendanceWorkerHubPage> createState() => _AttendanceWorkerHubPageState();
}

class _AttendanceWorkerHubPageState extends State<AttendanceWorkerHubPage> {
  late final AttendanceWorkerHubCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceWorkerHubCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceWorkerHubCubit, AttendanceWorkerHubState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is AttendanceWorkerHubInitial || state is AttendanceWorkerHubLoading) {
          return AttendanceScreenShell(
            title: 'Посещаемость',
            body: Center(
              child: CircularProgressIndicator(
                color: context.colors.serviceAccent(kAttendanceService).icon,
              ),
            ),
          );
        }

        final memberships = state is AttendanceWorkerHubLoaded
            ? state.memberships
            : const <AttendanceMembership>[];
        final snap = state is AttendanceWorkerHubLoaded ? state.snapshot : null;

        return AttendanceScreenShell(
          title: 'Посещаемость',
          body: memberships.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Нет активных компаний. Примите приглашение в чате.',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(15, color: context.colors.subTextColor),
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    for (final m in memberships) ...[
                      if (m.needsAck) _AckBanner(membership: m),
                      _WorkerCompanyCard(
                        membership: m,
                        dutyRoster: snap?.workplaceById(m.workplaceId)?.dutyRoster,
                        snapshot: snap,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _AckBanner extends StatelessWidget {
  const _AckBanner({required this.membership});

  final AttendanceMembership membership;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yellow = attendanceYellowAccent(colors);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: yellow.icon.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${membership.workplaceName}: примите правила v${membership.configVersion}',
              style: AppTextStyle.base(14, color: colors.textColor),
            ),
          ),
          TextButton(
            onPressed: () => openAttendanceCompanyChat(context, membership.workplaceId),
            child: Text(
              'Чат',
              style: AppTextStyle.base(14, color: colors.functionalSoftBlueIcon, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerCompanyCard extends StatelessWidget {
  const _WorkerCompanyCard({required this.membership, this.dutyRoster, this.snapshot});

  final AttendanceMembership membership;
  final AttendanceDutyRoster? dutyRoster;
  final AttendanceSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onShift = membership.shiftOpen;
    final accent = attendanceServiceAccent(colors);
    final now = AttendanceAnalytics.today;
    final monthStart = DateTime(now.year, now.month, 1);
    final selfId = membership.profileId ?? sl<AttendanceContextStore>().selfWorkerId();
    final analytics = snapshot == null
        ? null
        : AttendanceAnalytics.worker(
            snapshot: snapshot!,
            workplaceId: membership.workplaceId,
            workerId: selfId,
            start: monthStart,
            end: now,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(AppIcons.badge.icon, color: accent.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.workplaceName,
                      style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: onShift ? colors.functionalSoftBlue : colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: onShift ? colors.borderCardBlue.withValues(alpha: 0.8) : colors.borderSoft,
                        ),
                      ),
                      child: Text(
                        onShift ? 'на смене' : 'не на смене',
                        style: AppTextStyle.base(
                          12,
                          color: onShift ? colors.functionalSoftBlueIcon : colors.subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (membership.lastPunchLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Последнее: ${membership.lastPunchLabel}',
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ],
          if (dutyRoster != null && dutyRoster!.isConfigured) ...[
            const SizedBox(height: 12),
            AttendanceDutyTodayBanner(
              roster: dutyRoster!,
              selfWorkerId: selfId,
              displayNames: snapshot?.profileDisplayNames ?? const {},
              dutyOnlyPunch: snapshot?.workplaceById(membership.workplaceId)?.dutyOnlyPunch ?? false,
              compact: true,
            ),
          ],
          if (analytics != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.soft.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Часы', value: analytics.totalHoursLabel)),
                  Expanded(child: _MiniStat(label: 'Смены', value: '${analytics.daysWorked}')),
                  Expanded(child: _MiniStat(label: 'Опозд.', value: '${analytics.lateDays}')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AttendancePrimaryButton(
            text: 'Отметиться',
            isExpanded: true,
            onTap: membership.needsAck
                ? null
                : () => context.router.push(AttendancePunchRoute(workplaceId: membership.workplaceId)),
          ),
          const SizedBox(height: 8),
          AppOutlinedButton(
            text: 'Мои детали',
            isExpanded: true,
            service: kAttendanceService,
            onTap: () => context.router.push(
              AttendanceWorkerAnalyticsRoute(
                workplaceId: membership.workplaceId,
                workerId: selfId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(value, style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyle.base(11, color: colors.subTextColor)),
      ],
    );
  }
}
