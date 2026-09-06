import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_today_team_section.dart';
import 'package:clover/feature/_attendance_/attendance_company/presentation/cubit/attendance_company_cubit.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            title: 'Компания',
            body: Center(
              child: Text(
                'Компания не найдена',
                style: AppTextStyle.base(15, color: context.colors.subTextColor),
              ),
            ),
          );
        }

        final workplace = state is AttendanceCompanyLoaded
            ? state.workplace
            : (state as AttendanceCompanyLoading).workplace;
        final overview = state is AttendanceCompanyLoaded ? state.todayOverview : null;
        final workplaceId = widget.workplaceId;

        return AttendanceScreenShell(
          title: workplace.name,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (overview != null)
                  AttendanceTodayTeamSection(
                    workers: overview.workers,
                    workplaceId: workplaceId,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.serviceAccent(kAttendanceService).icon,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const _CompanySectionTitle('Компания'),
                AppTileGroup(
                  children: [
                    AttendanceServiceTile(
                      title: 'Настройки',
                      subtitle: 'Геозона, отметки, зарплата',
                      icon: AppIcons.tune.icon,
                      showChevron: true,
                      onTap: () =>
                          context.router.push(AttendanceWorkplaceSettingsRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Работники',
                      subtitle: 'Активные, приглашения, архив',
                      icon: AppIcons.groupOutlined.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceWorkersRoute(workplaceId: workplaceId)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CompanySectionTitle('Смены и учёт'),
                AppTileGroup(
                  children: [
                    AttendanceServiceTile(
                      title: 'Дежурные',
                      subtitle: 'Очередь по рабочим дням',
                      icon: AppIcons.eventAvailable.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceDutyRosterRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Отсутствия',
                      subtitle: 'Отпуск, больничный, выходной',
                      icon: AppIcons.eventBusy.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceAbsencesRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Переработка',
                      subtitle: 'Утверждение доплат',
                      icon: AppIcons.schedule.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceOvertimeRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Исправления',
                      subtitle: 'Запросы на правку отметок',
                      icon: AppIcons.editOutlined.icon,
                      showChevron: true,
                      onTap: () =>
                          context.router.push(AttendanceCorrectionsRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Табель',
                      subtitle: 'Экспорт CSV за месяц',
                      icon: AppIcons.description.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceTimesheetRoute(workplaceId: workplaceId)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CompanySectionTitle('Отчёты'),
                AppTileGroup(
                  children: [
                    AttendanceServiceTile(
                      title: 'Аналитика',
                      subtitle: 'Часы, команда, календарь, итог месяца',
                      icon: AppIcons.insights.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceAnalyticsRoute(workplaceId: workplaceId)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _CompanySectionTitle('Связь'),
                AppTileGroup(
                  children: [
                    AttendanceServiceTile(
                      title: 'Чат компании',
                      subtitle: 'Invite и правила — карточки',
                      icon: AppIcons.chat.icon,
                      showChevron: true,
                      onTap: () => openAttendanceCompanyChat(context, workplaceId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompanySectionTitle extends StatelessWidget {
  const _CompanySectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
