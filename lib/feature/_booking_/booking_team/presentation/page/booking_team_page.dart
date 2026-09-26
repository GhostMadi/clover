import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_invite.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_staff_profile_search_sheet.dart';
import 'package:clover/feature/_booking_/booking_team/presentation/cubit/booking_team_cubit.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingTeamPage extends StatefulWidget {
  const BookingTeamPage({super.key, required this.pointId});

  final String pointId;

  @override
  State<BookingTeamPage> createState() => _BookingTeamPageState();
}

class _BookingTeamPageState extends State<BookingTeamPage> {
  late final BookingTeamCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingTeamCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openAdd() async {
    HapticFeedback.selectionClick();
    await BookingStaffProfileSearchSheet.show(
      context,
      manageTeam: true,
    );
    if (!mounted) return;
    await _cubit.refresh();
  }

  Future<void> _openStaffSheet(BookingServiceExecutor person) async {
    HapticFeedback.selectionClick();
    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: person.displayName,
      upperCaseTitle: false,
      showCloseButton: true,
      service: kBookingService,
      contentBottomSpacing: 8,
      content: Builder(
        builder: (sheetContext) {
          final colors = sheetContext.colors;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                person.profileId != null && person.profileId!.isNotEmpty
                    ? (person.username.trim().isNotEmpty ? '@${person.username}' : context.l10n.booking_clover_account)
                    : context.l10n.booking_name_only_slots,
                style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 16),
              BookingPrimaryButton(
                text: context.l10n.booking_remove_from_team,
                isExpanded: true,
                height: 48,
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                text: context.l10n.common_close,
                isExpanded: true,
                height: 48,
                service: kBookingService,
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;
    await _remove(person);
  }

  Future<void> _openInviteSheet(BookingStaffInvite invite) async {
    HapticFeedback.selectionClick();
    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: invite.title,
      upperCaseTitle: false,
      showCloseButton: true,
      service: kBookingService,
      contentBottomSpacing: 8,
      content: Builder(
        builder: (sheetContext) {
          final colors = sheetContext.colors;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                invite.inviteeUsername?.trim().isNotEmpty == true
                    ? context.l10n.booking_waiting_chat_reply_user(invite.inviteeUsername!)
                    : context.l10n.booking_waiting_chat,
                style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 16),
              BookingPrimaryButton(
                text: context.l10n.booking_cancel_invite,
                isExpanded: true,
                height: 48,
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                text: context.l10n.common_close,
                isExpanded: true,
                height: 48,
                service: kBookingService,
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cancelInvite(invite);
  }

  Future<void> _remove(BookingServiceExecutor person) async {
    try {
      await _cubit.removeStaff(person.id);
      if (!mounted) return;
      AppSnackBar.show(context, message: context.l10n.booking_removed_from_team, kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _cancelInvite(BookingStaffInvite invite) async {
    try {
      await _cubit.cancelInvite(invite.id);
      if (!mounted) return;
      AppSnackBar.show(context, message: context.l10n.booking_invite_cancelled, kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingTeamCubit, BookingTeamState>(
      bloc: _cubit,
      builder: (context, state) {
        final staff = state.maybeMap(loaded: (s) => s.staff, orElse: () => const <BookingServiceExecutor>[]);
        final pending =
            state.maybeMap(loaded: (s) => s.pending, orElse: () => const <BookingStaffInvite>[]);
        final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && staff.isEmpty;

        return BookingScreenShell(
          title: context.l10n.booking_team,
          pointId: widget.pointId,
          onPointChanged: (nextId) {
            context.router.replace(BookingTeamRoute(pointId: nextId));
          },
          compactBar: true,
          isLoading: isLoading || isRefreshing,
          showAdd: true,
          onAddTap: _openAdd,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (staff.isEmpty && pending.isEmpty && !isLoading) {
                return RefreshIndicator(
                  onRefresh: _cubit.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                      _EmptyTeam(onAdd: _openAdd),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text(
                        context.l10n.booking_waiting_plural,
                        style: AppTextStyle.base(
                          14,
                          color: context.colors.subTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final invite in pending) ...[
                        _PersonTile(
                          title: invite.title,
                          subtitle: invite.inviteeUsername?.trim().isNotEmpty == true
                              ? '@${invite.inviteeUsername}'
                              : context.l10n.booking_waiting_chat,
                          avatarUrl: invite.inviteeAvatarUrl,
                          onTap: () => _openInviteSheet(invite),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                    if (staff.isNotEmpty) ...[
                      Text(
                        context.l10n.booking_in_team,
                        style: AppTextStyle.base(
                          14,
                          color: context.colors.subTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final person in staff) ...[
                        _PersonTile(
                          title: person.displayName,
                          subtitle: person.profileId != null && person.profileId!.isNotEmpty
                              ? (person.username.trim().isNotEmpty
                                  ? '@${person.username}'
                                  : context.l10n.booking_clover_account)
                              : context.l10n.booking_name_only_short,
                          avatarUrl: person.avatarUrl,
                          onTap: () => _openStaffSheet(person),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.soft, shape: BoxShape.circle),
              child: Icon(AppIcons.groupOutlined.icon, size: 34, color: accent.icon),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.booking_team_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.booking_team_empty_subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 20),
            BookingPrimaryButton(text: context.l10n.common_add, isExpanded: true, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.avatarUrl,
  });

  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = avatarUrl?.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surfaceSoft,
                  backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Icon(AppIcons.user.icon, color: colors.iconMuted, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight.icon, size: 20, color: colors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
