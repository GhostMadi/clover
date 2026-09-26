import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_corrections/presentation/cubit/attendance_corrections_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_corrections/presentation/widget/attendance_correction_card.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceCorrectionsPage extends StatefulWidget {
  const AttendanceCorrectionsPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceCorrectionsPage> createState() => _AttendanceCorrectionsPageState();
}

class _AttendanceCorrectionsPageState extends State<AttendanceCorrectionsPage> {
  late final AttendanceCorrectionsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceCorrectionsCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _resolve(String id, AttendanceCorrectionStatus status) async {
    try {
      await _cubit.resolve(correctionId: id, status: status);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: status == AttendanceCorrectionStatus.approved ? context.l10n.attendance_correction_status_approved : context.l10n.attendance_correction_status_rejected,
        kind: status == AttendanceCorrectionStatus.approved
            ? AppSnackBarKind.success
            : AppSnackBarKind.info,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : context.l10n.common_save_failed;
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCorrectionsCubit, AttendanceCorrectionsState>(
      bloc: _cubit,
      builder: (context, state) {
        final colors = context.colors;
        final all = state is AttendanceCorrectionsLoaded
            ? state.items
            : const <AttendanceCorrectionRequest>[];
        final pending = all.where((e) => e.status == AttendanceCorrectionStatus.pending).toList();
        final approved = all.where((e) => e.status == AttendanceCorrectionStatus.approved).toList();
        final rejected = all.where((e) => e.status == AttendanceCorrectionStatus.rejected).toList();
        final empty = pending.isEmpty && approved.isEmpty && rejected.isEmpty;

        return AttendanceScreenShell(
          title: context.l10n.attendance_corrections_title,
          body: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
              children: [
                if (state is AttendanceCorrectionsLoading && empty)
                  Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: AttendanceLoader(),
                  )
                else if (state is AttendanceCorrectionsError && empty)
                  Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: colors.subTextColor),
                        ),
                        SizedBox(height: 12),
                        AttendancePrimaryButton(
                          text: context.l10n.common_retry,
                          height: 44,
                          onTap: _cubit.refresh,
                        ),
                      ],
                    ),
                  )
                else if (empty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      context.l10n.attendance_corrections_empty,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(14, color: colors.subTextColor),
                    ),
                  )
                else ...[
                  if (pending.isNotEmpty) ...[
                    AttendanceSectionTitle(context.l10n.attendance_overtime_pending_section),
                    SizedBox(height: 8),
                    for (final item in pending) ...[
                      AttendanceCorrectionCard(
                        item: item,
                        onApprove: () => _resolve(item.id, AttendanceCorrectionStatus.approved),
                        onReject: () => _resolve(item.id, AttendanceCorrectionStatus.rejected),
                      ),
                      SizedBox(height: 8),
                    ],
                    SizedBox(height: 12),
                  ],
                  if (approved.isNotEmpty) ...[
                    AttendanceSectionTitle(context.l10n.attendance_corrections_approved_section),
                    SizedBox(height: 8),
                    for (final item in approved) ...[
                      AttendanceCorrectionCard(item: item),
                      SizedBox(height: 8),
                    ],
                    if (rejected.isNotEmpty) SizedBox(height: 12),
                  ],
                  if (rejected.isNotEmpty) ...[
                    AttendanceSectionTitle(context.l10n.attendance_overtime_rejected_section),
                    const SizedBox(height: 8),
                    for (final item in rejected) ...[
                      AttendanceCorrectionCard(item: item),
                      const SizedBox(height: 8),
                    ],
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
