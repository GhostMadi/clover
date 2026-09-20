import 'package:auto_route/auto_route.dart';
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
        message: status == AttendanceCorrectionStatus.approved ? 'Утверждено' : 'Отклонено',
        kind: status == AttendanceCorrectionStatus.approved
            ? AppSnackBarKind.success
            : AppSnackBarKind.info,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
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
          title: 'Исправления',
          body: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
              children: [
                if (state is AttendanceCorrectionsLoading && empty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: AttendanceLoader(),
                  )
                else if (state is AttendanceCorrectionsError && empty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: colors.subTextColor),
                        ),
                        const SizedBox(height: 12),
                        AttendancePrimaryButton(
                          text: 'Повторить',
                          height: 44,
                          onTap: _cubit.refresh,
                        ),
                      ],
                    ),
                  )
                else if (empty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Нет запросов на исправление',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(14, color: colors.subTextColor),
                    ),
                  )
                else ...[
                  if (pending.isNotEmpty) ...[
                    const AttendanceSectionTitle('Ожидают'),
                    const SizedBox(height: 8),
                    for (final item in pending) ...[
                      AttendanceCorrectionCard(
                        item: item,
                        onApprove: () => _resolve(item.id, AttendanceCorrectionStatus.approved),
                        onReject: () => _resolve(item.id, AttendanceCorrectionStatus.rejected),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (approved.isNotEmpty) ...[
                    const AttendanceSectionTitle('Утверждены'),
                    const SizedBox(height: 8),
                    for (final item in approved) ...[
                      AttendanceCorrectionCard(item: item),
                      const SizedBox(height: 8),
                    ],
                    if (rejected.isNotEmpty) const SizedBox(height: 12),
                  ],
                  if (rejected.isNotEmpty) ...[
                    const AttendanceSectionTitle('Отклонены'),
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
