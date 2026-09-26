import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_absences/presentation/cubit/attendance_absences_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_absences/presentation/widget/attendance_absence_add_sheet.dart';
import 'package:clover/feature/_attendance_/attendance_absences/presentation/widget/attendance_absence_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceAbsencesPage extends StatefulWidget {
  const AttendanceAbsencesPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceAbsencesPage> createState() => _AttendanceAbsencesPageState();
}

class _AttendanceAbsencesPageState extends State<AttendanceAbsencesPage> {
  late final AttendanceAbsencesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceAbsencesCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _add() async {
    HapticFeedback.selectionClick();
    final loaded = _cubit.state is AttendanceAbsencesLoaded
        ? _cubit.state as AttendanceAbsencesLoaded
        : null;
    final workers = loaded?.workers ?? const <AttendanceWorkerListItem>[];
    await AttendanceAbsenceAddSheet.show(
      context,
      workplaceId: widget.workplaceId,
      workers: workers,
      cubit: _cubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceAbsencesCubit, AttendanceAbsencesState>(
      bloc: _cubit,
      builder: (context, state) {
        final loaded = state is AttendanceAbsencesLoaded ? state : null;
        final absences = loaded?.absences ?? const <AttendanceAbsenceEntry>[];
        final snap = loaded?.snapshot;

        return AttendanceScreenShell(
          title: context.l10n.attendance_absences_title,
          showAdd: true,
          onAddTap: _add,
          body: absences.isEmpty
              ? ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                    _EmptyAbsences(onAdd: _add),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    for (final entry in absences) ...[
                      AttendanceAbsenceTile(
                        entry: entry,
                        workerName: snap
                                ?.workersFor(widget.workplaceId)
                                .where((w) => w.id == entry.workerId)
                                .map((w) => w.displayName)
                                .firstOrNull ??
                            entry.workerId,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _EmptyAbsences extends StatelessWidget {
  const _EmptyAbsences({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = attendanceServiceAccent(context.colors);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.soft, shape: BoxShape.circle),
              child: Icon(AppIcons.eventBusy.icon, size: 34, color: accent.icon),
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.attendance_absences_empty,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.attendance_absences_add_hint,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            SizedBox(height: 20),
            AttendancePrimaryButton(text: context.l10n.common_add, isExpanded: true, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}
