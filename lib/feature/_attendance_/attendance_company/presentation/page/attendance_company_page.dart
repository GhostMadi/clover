import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/attendance_company/presentation/cubit/attendance_company_cubit.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_hub_nav_card.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clover/core/extension/context.dart';

@RoutePage()
class AttendanceCompanyPage extends StatefulWidget {
  const AttendanceCompanyPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceCompanyPage> createState() => _AttendanceCompanyPageState();
}

class _AttendanceCompanyPageState extends State<AttendanceCompanyPage> {
  late final AttendanceCompanyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceCompanyCubit>()..load(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCompanyCubit, AttendanceCompanyState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is AttendanceCompanyMissing || state is AttendanceCompanyInitial) {
          return AttendanceScreenShell(
            title: context.l10n.attendance_company_default_name,
            body: Center(
              child: Text(
                context.l10n.attendance_company_not_found,
                style: AppTextStyle.base(15, color: context.colors.subTextColor),
              ),
            ),
          );
        }

        if (state is AttendanceCompanyLoading) {
          return AttendanceScreenShell(
            title: context.l10n.attendance_company_default_name,
            body: AttendanceLoader(),
          );
        }

        final workplace = (state as AttendanceCompanyLoaded).workplace;
        final workplaceId = widget.workplaceId;

        return AttendanceScreenShell(
          title: workplace.name,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: AttendanceHubNavGrid(
              children: [
                AttendanceHubNavCard(
                  title: context.l10n.attendance_workers_title,
                  subtitle: context.l10n.attendance_company_team_invites,
                  icon: AppIcons.groupOutlined.icon,
                  onTap: () => context.router.push(AttendanceWorkersRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.common_settings,
                  subtitle: context.l10n.attendance_company_geofence_punches,
                  icon: AppIcons.tune.icon,
                  onTap: () =>
                      context.router.push(AttendanceWorkplaceSettingsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_duty_title,
                  subtitle: context.l10n.attendance_company_duty_queue,
                  icon: AppIcons.eventAvailable.icon,
                  onTap: () => context.router.push(AttendanceDutyRosterRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_absences_title,
                  subtitle: context.l10n.attendance_company_leave_sick,
                  icon: AppIcons.eventBusy.icon,
                  onTap: () => context.router.push(AttendanceAbsencesRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_payroll_overtime,
                  subtitle: context.l10n.attendance_company_ot_approval,
                  icon: AppIcons.schedule.icon,
                  onTap: () => context.router.push(AttendanceOvertimeRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_corrections_title,
                  subtitle: context.l10n.attendance_company_punch_edits,
                  icon: AppIcons.editOutlined.icon,
                  onTap: () => context.router.push(AttendanceCorrectionsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_timesheet_title,
                  subtitle: context.l10n.attendance_company_export_month,
                  icon: AppIcons.description.icon,
                  onTap: () => context.router.push(AttendanceTimesheetRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.attendance_analytics_title,
                  subtitle: context.l10n.attendance_company_hours_team,
                  icon: AppIcons.insights.icon,
                  onTap: () => context.router.push(AttendanceAnalyticsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: context.l10n.common_chat,
                  subtitle: context.l10n.attendance_company_invite_rules,
                  icon: AppIcons.chat.icon,
                  onTap: () => openAttendanceCompanyChat(context, workplaceId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
