import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_attendance_/attendance_corrections/presentation/cubit/attendance_corrections_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
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
  int _tabIndex = 0;

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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCorrectionsCubit, AttendanceCorrectionsState>(
      bloc: _cubit,
      builder: (context, state) {
        final colors = context.colors;
        final accent = attendanceServiceAccent(colors);
        final yellow = attendanceYellowAccent(colors);

        final all = state is AttendanceCorrectionsLoaded
            ? state.items
            : const <AttendanceCorrectionRequest>[];
        final pending =
            all.where((e) => e.status == AttendanceCorrectionStatus.pending).toList();
        final approved =
            all.where((e) => e.status == AttendanceCorrectionStatus.approved).toList();
        final rejected =
            all.where((e) => e.status == AttendanceCorrectionStatus.rejected).toList();
        final list = switch (_tabIndex) {
          1 => approved,
          2 => rejected,
          _ => pending,
        };

        return AttendanceScreenShell(
          title: 'Исправления',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cubit.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      AttendanceScreenShell.scrollBottomGap(context),
                    ),
                    children: [
                      Text(
                        'Работник просит поправить отметку. Утвердите — время обновится; отклоните — без изменений.',
                        style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      AppTab(
                        tabs: [
                          'Ожидают · ${pending.length}',
                          'Утверждены · ${approved.length}',
                          'Отклонены · ${rejected.length}',
                        ],
                        currentIndex: _tabIndex,
                        onTabChanged: (i) => setState(() => _tabIndex = i),
                        service: kAttendanceService,
                      ),
                      const SizedBox(height: 16),
                      if (state is AttendanceCorrectionsLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: accent.icon),
                          ),
                        )
                      else if (state is AttendanceCorrectionsError)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
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
                      else if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            switch (_tabIndex) {
                              1 => 'Нет утверждённых запросов',
                              2 => 'Нет отклонённых запросов',
                              _ => 'Нет ожидающих запросов',
                            },
                            textAlign: TextAlign.center,
                            style: AppTextStyle.base(14, color: colors.subTextColor),
                          ),
                        )
                      else
                        for (final item in list)
                          _CorrectionCard(
                            item: item,
                            formatTime: _fmt,
                            accent: accent,
                            yellow: yellow,
                            onApprove: () => _resolve(item.id, AttendanceCorrectionStatus.approved),
                            onReject: () => _resolve(item.id, AttendanceCorrectionStatus.rejected),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resolve(String id, AttendanceCorrectionStatus status) async {
    try {
      await _cubit.resolve(correctionId: id, status: status);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: status == AttendanceCorrectionStatus.approved
            ? 'Исправление утверждено'
            : 'Запрос отклонён',
        kind: status == AttendanceCorrectionStatus.approved
            ? AppSnackBarKind.success
            : AppSnackBarKind.info,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить решение';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({
    required this.item,
    required this.formatTime,
    required this.accent,
    required this.yellow,
    required this.onApprove,
    required this.onReject,
  });

  final AttendanceCorrectionRequest item;
  final String Function(DateTime) formatTime;
  final AppServiceAccent accent;
  final ({Color surface, Color icon}) yellow;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (item.status) {
      AttendanceCorrectionStatus.pending => yellow.icon,
      AttendanceCorrectionStatus.approved => accent.icon,
      AttendanceCorrectionStatus.rejected => colors.destructive,
    };

    final punched = item.punchedAt;
    final proposed = item.proposedPunchedAt;
    final note = item.note?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.workerName,
                  style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.labelRu,
                  style: AppTextStyle.base(12, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.punchKindLabelRu,
            style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w600),
          ),
          if (punched != null) ...[
            const SizedBox(height: 2),
            Text(
              'Сейчас: ${formatTime(punched)}',
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ],
          if (proposed != null) ...[
            const SizedBox(height: 2),
            Text(
              'Предлагает: ${formatTime(proposed)}',
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35)),
          ],
          const SizedBox(height: 4),
          Text(
            'Запрос · ${formatTime(item.createdAt)}',
            style: AppTextStyle.base(12, color: colors.subTextColor),
          ),
          if (item.status == AttendanceCorrectionStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AttendancePrimaryButton(
                    text: 'Утвердить',
                    height: 44,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    text: 'Отклонить',
                    height: 44,
                    service: kAttendanceService,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
