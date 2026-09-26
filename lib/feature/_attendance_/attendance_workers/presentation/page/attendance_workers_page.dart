import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/cubit/attendance_workers_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/widget/attendance_worker_search_sheet.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/widget/attendance_workers_empty.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/widget/attendance_workers_person_tile.dart';
import 'package:clover/feature/_attendance_/attendance_workers/presentation/widget/attendance_workers_sheets.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clover/core/extension/context.dart';

@RoutePage()
class AttendanceWorkersPage extends StatefulWidget {
  const AttendanceWorkersPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceWorkersPage> createState() => _AttendanceWorkersPageState();
}

class _AttendanceWorkersPageState extends State<AttendanceWorkersPage> {
  late final AttendanceWorkersCubit _cubit;

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

  Future<void> _onActive(AttendanceWorkerListItem worker) async {
    HapticFeedback.selectionClick();
    final action = await AttendanceWorkersSheets.showActive(context, worker);
    if (!mounted || action == null) return;
    if (action == AttendanceWorkerSheetAction.open) {
      await context.router.push(
        AttendanceWorkerAnalyticsRoute(
          workplaceId: widget.workplaceId,
          workerId: worker.id,
        ),
      );
      return;
    }
    if (action == AttendanceWorkerSheetAction.archive) {
      await _archive(worker);
    }
  }

  Future<void> _onPending(AttendanceWorkerListItem worker) async {
    HapticFeedback.selectionClick();
    final action = await AttendanceWorkersSheets.showPending(context, worker);
    if (action != AttendanceWorkerSheetAction.openChat || !mounted) return;
    openAttendanceInviteDm(
      context,
      dm: AttendanceInviteDm(
        conversationId: '',
        otherUserId: worker.id,
        username: worker.username.trim().isEmpty ? worker.displayName : worker.username,
      ),
    );
  }

  Future<void> _onArchived(AttendanceWorkerListItem worker) async {
    HapticFeedback.selectionClick();
    final action = await AttendanceWorkersSheets.showArchived(context, worker);
    if (!mounted || action == null) return;
    if (action == AttendanceWorkerSheetAction.open) {
      await context.router.push(
        AttendanceWorkerAnalyticsRoute(
          workplaceId: widget.workplaceId,
          workerId: worker.id,
        ),
      );
      return;
    }
    if (action == AttendanceWorkerSheetAction.reinvite) {
      await _inviteAndOpenChat(worker);
    }
  }

  Future<void> _archive(AttendanceWorkerListItem worker) async {
    try {
      await _cubit.setWorkerStatus(
        workerId: worker.id,
        status: AttendanceWorkerInviteStatus.archived,
      );
      if (!mounted) return;
      AppSnackBar.show(context, message: context.l10n.attendance_workers_archived_toast, kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e is AttendanceException ? e.userMessage : context.l10n.attendance_workers_archive_failed,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _showAddWorker() async {
    HapticFeedback.selectionClick();
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
      AppSnackBar.show(context, message: context.l10n.attendance_workers_invite_sent, kind: AppSnackBarKind.success);
      if (dm != null) {
        openAttendanceInviteDm(context, dm: dm);
      } else {
        openAttendanceCompanyChat(context, widget.workplaceId);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is AttendanceException
          ? e.userMessage
          : (e is ChatRepositoryException ? e.message : context.l10n.attendance_workers_invite_failed);
      AppSnackBar.show(context, message: message, kind: AppSnackBarKind.error);
    }
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
        final empty = pending.isEmpty && active.isEmpty && archived.isEmpty;

        return AttendanceScreenShell(
          title: context.l10n.attendance_workers_title,
          showAdd: true,
          onAddTap: _showAddWorker,
          body: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: empty
                ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                      AttendanceWorkersEmpty(onAdd: _showAddWorker),
                    ],
                  )
                : ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _SectionTitle(context.l10n.attendance_overtime_pending_section),
                        const SizedBox(height: 8),
                        for (final worker in pending) ...[
                          AttendanceWorkersPersonTile(
                            title: worker.displayName,
                            subtitle: context.l10n.attendance_workers_waiting_reply(AttendanceWorkersSheets.usernameLine(context, worker)),
                            onTap: () => _onPending(worker),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 12),
                      ],
                      if (active.isNotEmpty) ...[
                        _SectionTitle(context.l10n.attendance_workers_in_team),
                        const SizedBox(height: 8),
                        for (final worker in active) ...[
                          AttendanceWorkersPersonTile(
                            title: worker.displayName,
                            subtitle: worker.isTagInactive
                                ? context.l10n.attendance_workers_no_tag(AttendanceWorkersSheets.usernameLine(context, worker))
                                : AttendanceWorkersSheets.usernameLine(context, worker),
                            onTap: () => _onActive(worker),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (archived.isNotEmpty) const SizedBox(height: 12),
                      ],
                      if (archived.isNotEmpty) ...[
                        _SectionTitle(context.l10n.common_archive),
                        const SizedBox(height: 8),
                        for (final worker in archived) ...[
                          AttendanceWorkersPersonTile(
                            title: worker.displayName,
                            subtitle: context.l10n.attendance_workers_in_archive(AttendanceWorkersSheets.usernameLine(context, worker)),
                            muted: true,
                            onTap: () => _onArchived(worker),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyle.base(
        14,
        color: context.colors.subTextColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
