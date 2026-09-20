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

        if (state is AttendanceCompanyLoading) {
          return const AttendanceScreenShell(
            title: 'Компания',
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
                  title: 'Работники',
                  subtitle: 'Команда и приглашения',
                  icon: AppIcons.groupOutlined.icon,
                  onTap: () => context.router.push(AttendanceWorkersRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Настройки',
                  subtitle: 'Геозона и отметки',
                  icon: AppIcons.tune.icon,
                  onTap: () =>
                      context.router.push(AttendanceWorkplaceSettingsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Дежурные',
                  subtitle: 'Очередь по дням',
                  icon: AppIcons.eventAvailable.icon,
                  onTap: () => context.router.push(AttendanceDutyRosterRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Отсутствия',
                  subtitle: 'Отпуск и больничный',
                  icon: AppIcons.eventBusy.icon,
                  onTap: () => context.router.push(AttendanceAbsencesRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Переработка',
                  subtitle: 'Утверждение доплат',
                  icon: AppIcons.schedule.icon,
                  onTap: () => context.router.push(AttendanceOvertimeRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Исправления',
                  subtitle: 'Правки отметок',
                  icon: AppIcons.editOutlined.icon,
                  onTap: () => context.router.push(AttendanceCorrectionsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Табель',
                  subtitle: 'Экспорт за месяц',
                  icon: AppIcons.description.icon,
                  onTap: () => context.router.push(AttendanceTimesheetRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Аналитика',
                  subtitle: 'Часы и команда',
                  icon: AppIcons.insights.icon,
                  onTap: () => context.router.push(AttendanceAnalyticsRoute(workplaceId: workplaceId)),
                ),
                AttendanceHubNavCard(
                  title: 'Чат',
                  subtitle: 'Invite и правила',
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
