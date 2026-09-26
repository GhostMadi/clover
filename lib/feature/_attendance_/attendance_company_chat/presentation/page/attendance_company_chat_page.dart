import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_company_chat/presentation/cubit/attendance_company_chat_cubit.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clover/core/extension/context.dart';

/// Карточки invite и правил компании (Accept/ack через RPC при remote).
@RoutePage()
class AttendanceCompanyChatPage extends StatefulWidget {
  const AttendanceCompanyChatPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceCompanyChatPage> createState() => _AttendanceCompanyChatPageState();
}

class _AttendanceCompanyChatPageState extends State<AttendanceCompanyChatPage> {
  late final AttendanceCompanyChatCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceCompanyChatCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCompanyChatCubit, AttendanceCompanyChatState>(
      bloc: _cubit,
      builder: (context, state) {
        final loaded = state is AttendanceCompanyChatLoaded ? state : null;
        final workplace = loaded?.workplace;
        final title = workplace == null ? context.l10n.attendance_chat_title : context.l10n.attendance_chat_title_named(workplace.name);
        final pending = loaded?.pendingWorkers ?? const [];
        final membership = loaded?.membership;
        final needsAck = membership?.needsAck ?? false;
        final configVersion = membership?.configVersion ?? 1;

        return AttendanceScreenShell(
          title: title,
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              _DayDivider(label: context.l10n.common_today),
              const SizedBox(height: 12),
              _SystemLine(text: context.l10n.attendance_chat_system_intro),
              const SizedBox(height: 16),
              if (pending.isEmpty && !needsAck)
                Text(
                  context.l10n.attendance_chat_no_cards,
                  style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
                ),
              for (final worker in pending) ...[
                _InviteCard(
                  workplaceName: workplace?.name ?? context.l10n.attendance_company_fallback,
                  worker: worker,
                  onAccept: () async {
                    await _cubit.acceptInvite(worker.id);
                    if (!context.mounted) return;
                    AppSnackBar.show(
                      context,
                      message: context.l10n.attendance_chat_accepted(worker.displayName),
                      kind: AppSnackBarKind.success,
                    );
                  },
                  onReject: () async {
                    await _cubit.rejectInvite(worker.id);
                    if (!context.mounted) return;
                    AppSnackBar.show(
                      context,
                      message: context.l10n.attendance_chat_declined,
                      kind: AppSnackBarKind.info,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (needsAck) ...[
                _RulesCard(
                  workplaceName: workplace?.name ?? context.l10n.attendance_company_fallback,
                  version: configVersion,
                  onAck: () async {
                    await _cubit.ackConfig();
                    if (!context.mounted) return;
                    AppSnackBar.show(
                      context,
                      message: context.l10n.attendance_rules_accepted('$configVersion'),
                      kind: AppSnackBarKind.success,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: AppTextStyle.base(12, color: colors.subTextColor)),
        ),
        Expanded(child: Divider(color: colors.divider)),
      ],
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.workplaceName,
    required this.worker,
    required this.onAccept,
    required this.onReject,
  });

  final String workplaceName;
  final AttendanceWorkerListItem worker;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.icon.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(AppIcons.badge.icon, color: accent.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.attendance_chat_join_team,
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                workplaceName,
                style: AppTextStyle.base(14, color: accent.icon, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.attendance_invite_body(worker.displayName, worker.username),
                style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AttendancePrimaryButton(
                      text: context.l10n.common_accept,
                      height: 44,
                      onTap: onAccept,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppOutlinedButton(
                      text: context.l10n.common_reject,
                      height: 44,
                      service: kAttendanceService,
                      onTap: onReject,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({
    required this.workplaceName,
    required this.version,
    required this.onAck,
  });

  final String workplaceName;
  final int version;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yellow = attendanceYellowAccent(colors);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: yellow.icon.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(AppIcons.infoOutline.icon, color: yellow.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.attendance_rules_updated('$version'),
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                workplaceName,
                style: AppTextStyle.base(14, color: yellow.icon, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.attendance_rules_changed_body,
                style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 12),
              AttendancePrimaryButton(
                text: context.l10n.attendance_chat_rules_accept_cta,
                height: 44,
                isExpanded: true,
                onTap: onAck,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
