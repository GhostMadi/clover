import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/cubit/attendance_workers_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/widget/attendance_worker_search_sheet.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceWorkersPage extends StatefulWidget {
  const AttendanceWorkersPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceWorkersPage> createState() => _AttendanceWorkersPageState();
}

class _AttendanceWorkersPageState extends State<AttendanceWorkersPage> {
  late final AttendanceWorkersCubit _cubit;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceWorkersCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceWorkersCubit, AttendanceWorkersState>(
      bloc: _cubit,
      builder: (context, state) {
        final snap = state is AttendanceWorkersLoaded ? state.snapshot : null;
        final workers = snap?.workersFor(widget.workplaceId) ?? const <AttendanceWorkerListItem>[];

        final pending = workers.where((w) => w.isPending).toList(growable: false);
        final active = workers.where((w) => w.isAccepted).toList(growable: false);
        final archived = workers.where((w) => w.isArchived).toList(growable: false);

        final now = AttendanceAnalytics.today;
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = now;

        final list = switch (_tabIndex) {
          1 => pending,
          2 => archived,
          _ => active,
        };

        return AttendanceScreenShell(
          title: 'Работники',
          showAdd: true,
          onAddTap: () => _showAddWorker(context),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppTab(
                  tabs: [
                    'Активные · ${active.length}',
                    'Ожидают · ${pending.length}',
                    'Архив · ${archived.length}',
                  ],
                  currentIndex: _tabIndex,
                  onTabChanged: (index) => setState(() => _tabIndex = index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  switch (_tabIndex) {
                    1 => 'Приглашение отправлено в чат. Пока не приняли — отметок нет.',
                    2 => 'Не в сменах и зарплате. История сохранена — можно вернуть.',
                    _ => 'Нажмите — действия. Долгое нажатие — сразу в архив.',
                  },
                  style: AppTextStyle.base(13, color: context.colors.subTextColor),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          switch (_tabIndex) {
                            1 => 'Нет ожидающих приглашений',
                            2 => 'Архив пуст',
                            _ => 'Нет активных работников',
                          },
                          style: AppTextStyle.base(15, color: context.colors.subTextColor),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          AttendanceScreenShell.scrollBottomGap(context),
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final worker = list[index];
                          return switch (_tabIndex) {
                            1 => _WorkerTile(
                                worker: worker,
                                onTap: () => _showPendingWorker(context, worker, snap),
                              ),
                            2 => _WorkerTile(
                                worker: worker,
                                onTap: () => _showArchived(context, worker, snap),
                              ),
                            _ => _WorkerTile(
                                worker: worker,
                                hoursLabel: _hoursLabel(snap, worker, monthStart, monthEnd),
                                onTap: () => _onActiveTap(context, worker),
                                onLongPress: () => _showArchiveWorker(context, worker),
                              ),
                          };
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _hoursLabel(
    AttendanceSnapshot? snap,
    AttendanceWorkerListItem worker,
    DateTime start,
    DateTime end,
  ) {
    if (snap == null) return null;
    final analytics = AttendanceAnalytics.worker(
      snapshot: snap,
      workplaceId: widget.workplaceId,
      workerId: worker.id,
      start: start,
      end: end,
    );
    return analytics?.totalHoursLabel;
  }

  void _onActiveTap(BuildContext context, AttendanceWorkerListItem worker) {
    HapticFeedback.lightImpact();
    _showActiveWorker(context, worker);
  }

  Future<void> _showActiveWorker(BuildContext context, AttendanceWorkerListItem worker) {
    return AttendanceBottomSheet.show(
      context: context,
      title: worker.displayName,
      content: Text(
        '${worker.username}\n\nКалендарь и часы — в деталях. Архив убирает из смен и зарплаты.',
        style: AppTextStyle.base(15, color: context.colors.subTextColor, height: 1.4),
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Просмотреть детально',
          isExpanded: true,
          onTap: () {
            Navigator.of(context).pop();
            context.router.push(
              AttendanceWorkerAnalyticsRoute(
                workplaceId: widget.workplaceId,
                workerId: worker.id,
              ),
            );
          },
        ),
        AppOutlinedButton(
          text: 'В архив',
          isExpanded: true,
          service: kAttendanceService,
          onTap: () {
            Navigator.of(context).pop();
            _showArchiveWorker(context, worker);
          },
        ),
      ],
    );
  }

  Future<void> _showArchiveWorker(BuildContext context, AttendanceWorkerListItem worker) {
    return AttendanceBottomSheet.show(
      context: context,
      title: 'В архив?',
      content: Text(
        '${worker.displayName} не будет в активных сменах и расчёте зарплаты. История сохранится.',
        style: AppTextStyle.base(15, color: context.colors.subTextColor),
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'В архив',
          isExpanded: true,
          onTap: () {
            _cubit.setWorkerStatus(
              workerId: worker.id,
              status: AttendanceWorkerInviteStatus.archived,
            );
            Navigator.of(context).pop();
            AppSnackBar.show(context, message: 'Перемещён в архив', kind: AppSnackBarKind.success);
          },
        ),
      ],
    );
  }

  Future<void> _showArchived(
    BuildContext context,
    AttendanceWorkerListItem worker,
    AttendanceSnapshot? snap,
  ) {
    final workplaceName = snap?.workplaceById(widget.workplaceId)?.name ?? 'компанию';

    return AttendanceBottomSheet.show(
      context: context,
      title: worker.displayName,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(worker.username, style: AppTextStyle.base(14, color: context.colors.subTextColor)),
          const SizedBox(height: 12),
          Text(
            'В архиве: не в сменах и зарплате, история сохранена.\n\n'
            'Повторное приглашение уходит в чат — карточка «Стать частью команды · $workplaceName». '
            'Пока человек не примет, снова будет в «Ожидают».',
            style: AppTextStyle.base(15, color: context.colors.subTextColor, height: 1.4),
          ),
        ],
      ),
      actions: [
        AppOutlinedButton(
          text: 'Просмотреть детально',
          isExpanded: true,
          service: kAttendanceService,
          onTap: () {
            Navigator.of(context).pop();
            context.router.push(
              AttendanceWorkerAnalyticsRoute(
                workplaceId: widget.workplaceId,
                workerId: worker.id,
              ),
            );
          },
        ),
        AttendancePrimaryButton(
          text: 'Пригласить повторно',
          isExpanded: true,
          onTap: () => _reinviteWorker(context, worker),
        ),
      ],
    );
  }

  Future<void> _reinviteWorker(BuildContext context, AttendanceWorkerListItem worker) async {
    Navigator.of(context).pop();
    await _inviteAndOpenChat(worker);
  }

  Future<void> _showPendingWorker(
    BuildContext context,
    AttendanceWorkerListItem worker,
    AttendanceSnapshot? snap,
  ) {
    final workplaceName = snap?.workplaceById(widget.workplaceId)?.name ?? 'компанию';

    return AttendanceBottomSheet.show(
      context: context,
      title: worker.displayName,
      content: Text(
        'В чат ушла заявка «Стать частью команды · $workplaceName». '
        'Пока ${worker.username} не примет её, календарь и часы недоступны.\n\n'
        'Accept / Отклонить — пока в карточке чата компании (позже в этом DM). '
        'Диалог уже во вкладке Chat.',
        style: AppTextStyle.base(15, color: context.colors.subTextColor, height: 1.4),
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Открыть чат',
          isExpanded: true,
          onTap: () {
            Navigator.of(context).pop();
            openAttendanceInviteDm(
              context,
              dm: AttendanceInviteDm(
                conversationId: '',
                otherUserId: worker.id,
                username: worker.username.trim().isEmpty ? worker.displayName : worker.username,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddWorker(BuildContext context) async {
    final profile = await AttendanceWorkerSearchSheet.show(
      context,
      search: _cubit.searchProfiles,
    );
    if (profile == null || !mounted) return;

    await _inviteAndOpenChat(
      AttendanceWorkerListItem(
        id: profile.id,
        displayName: profile.title,
        username: profile.displayUsername,
        status: AttendanceWorkerInviteStatus.pending,
      ),
    );
  }

  Future<void> _inviteAndOpenChat(AttendanceWorkerListItem worker) async {
    try {
      final dm = await _cubit.sendChatInvite(worker);
      if (!mounted) return;
      setState(() => _tabIndex = 1);
      AppSnackBar.show(
        context,
        message: 'Приглашение в чат · ${worker.displayName}',
        kind: AppSnackBarKind.success,
      );
      if (dm != null) {
        openAttendanceInviteDm(context, dm: dm);
      } else {
        openAttendanceCompanyChat(context, widget.workplaceId);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is AttendanceException
          ? e.userMessage
          : (e is ChatRepositoryException ? e.message : 'Не удалось отправить приглашение');
      AppSnackBar.show(context, message: message, kind: AppSnackBarKind.error);
    }
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({
    required this.worker,
    required this.onTap,
    this.hoursLabel,
    this.onLongPress,
  });

  final AttendanceWorkerListItem worker;
  final String? hoursLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (worker.isAccepted) {
      final accent = attendanceServiceAccent(colors);
      return GestureDetector(
        onLongPress: onLongPress,
        child: AppTile(
          title: worker.displayName,
          subtitle:
              '${worker.username} · ${worker.status.labelRu}${hoursLabel != null ? ' · $hoursLabel' : ''}',
          icon: AppIcons.badge.icon,
          iconColor: accent.icon,
          iconBackgroundColor: accent.soft,
          showChevron: true,
          filled: true,
          onTap: onTap,
        ),
      );
    }

    final Color iconColor;
    final Color bgColor;
    if (worker.isPending) {
      final waiting = attendanceWaitingAccent(colors);
      iconColor = waiting.icon;
      bgColor = waiting.surface;
    } else {
      iconColor = colors.subTextColor;
      bgColor = colors.surfaceMuted;
    }

    return AppTile(
      title: worker.displayName,
      subtitle: '${worker.username} · ${worker.status.labelRu}',
      icon: AppIcons.badge.icon,
      iconColor: iconColor,
      iconBackgroundColor: bgColor,
      showChevron: true,
      filled: true,
      onTap: onTap,
    );
  }
}
