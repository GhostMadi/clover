import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_staff_search_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pick linked staff for a service, invite Clover account, or add name-only.
abstract final class BookingStaffProfileSearchSheet {
  static Future<BookingServiceExecutor?> show(
    BuildContext context, {
    Set<String> excludeStaffIds = const {},
    Set<String> excludeProfileIds = const {},
    /// Экран «Команда»: только пригласить / добавить имя, без выбора на услугу.
    bool manageTeam = false,
  }) {
    return AppBottomSheet.show<BookingServiceExecutor>(
      service: kBookingService,
      context: context,
      title: manageTeam ? 'Добавить' : 'Исполнители',
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _Body(
        excludeStaffIds: excludeStaffIds,
        excludeProfileIds: excludeProfileIds,
        manageTeam: manageTeam,
      ),
    );
  }
}

enum _SheetMode { pick, invite, nameOnly }

class _Body extends StatefulWidget {
  const _Body({
    required this.excludeStaffIds,
    required this.excludeProfileIds,
    this.manageTeam = false,
  });

  final Set<String> excludeStaffIds;
  final Set<String> excludeProfileIds;
  final bool manageTeam;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final BookingStaffSearchCubit _cubit;
  late final TextEditingController _queryController;
  late final TextEditingController _nameController;

  _SheetMode _mode = _SheetMode.pick;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingStaffSearchCubit>()
      ..configure(excludeProfileIds: {...widget.excludeProfileIds})
      ..loadTeam();
    _queryController = TextEditingController();
    _nameController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _nameController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onQueryChanged() {
    if (_mode == _SheetMode.invite) {
      _cubit.search(_queryController.text);
    }
  }

  Future<void> _invite(BookingStaffProfile profile) async {
    await _cubit.invite(profile.id);
  }

  Future<void> _cancelInvite(String inviteId) async {
    await _cubit.cancelInvite(inviteId);
  }

  Future<void> _createNameOnly() async {
    final staff = await _cubit.createNameOnly(_nameController.text);
    if (!mounted || staff == null) return;
    Navigator.of(context).pop(staff);
  }

  List<BookingServiceExecutor> _availableStaff(BookingStaffSearchState state) {
    return [
      for (final person in state.staff)
        if (!widget.excludeStaffIds.contains(person.id)) person,
    ];
  }

  String? _inviteStatusLabel(BookingStaffSearchState state, String profileId) {
    final id = profileId.trim();
    if (id.isEmpty) return null;
    if (state.staff.any((s) => s.profileId?.trim() == id)) return 'В команде';
    if (state.pending.any((i) => i.inviteeId.trim() == id)) return 'Приглашён';
    return null;
  }

  void _handleAction(BookingStaffSearchState state) {
    final action = state.lastAction;
    if (action == null) return;
    switch (action) {
      case BookingStaffSheetAction.invited:
        AppSnackBar.show(context, message: 'Приглашение отправлено в чат', kind: AppSnackBarKind.success);
        setState(() => _mode = _SheetMode.pick);
      case BookingStaffSheetAction.inviteCancelled:
        AppSnackBar.show(context, message: 'Заявка отменена', kind: AppSnackBarKind.success);
      case BookingStaffSheetAction.created:
        break;
      case BookingStaffSheetAction.failed:
        final message = state.actionError;
        if (message != null && message.isNotEmpty) {
          AppSnackBar.show(context, message: message, kind: AppSnackBarKind.error);
        }
    }
    _cubit.clearLastAction();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingStaffSearchCubit, BookingStaffSearchState>(
      bloc: _cubit,
      listenWhen: (prev, next) => prev.lastAction != next.lastAction && next.lastAction != null,
      listener: (context, state) => _handleAction(state),
      builder: (context, state) {
        if (state.loadingTeam && state.staff.isEmpty && state.pending.isEmpty) {
          return const BookingLoader(strokeWidth: 2);
        }

        return switch (_mode) {
          _SheetMode.pick => _buildPick(context, state),
          _SheetMode.invite => _buildInvite(context, state),
          _SheetMode.nameOnly => _buildNameOnly(context, state),
        };
      },
    );
  }

  Widget _buildPick(BuildContext context, BookingStaffSearchState state) {
    final available = _availableStaff(state);
    final manage = widget.manageTeam;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (!manage) ...[
                Text(
                  'Уже в команде',
                  style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (available.isEmpty)
                  Text(
                    'Пока никого нет — пригласите аккаунт Clover или добавьте имя.',
                    style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
                  )
                else
                  for (final person in available) ...[
                    _StaffTile(
                      title: person.displayName,
                      subtitle: person.username.trim().isNotEmpty ? '@${person.username}' : null,
                      avatarUrl: person.avatarUrl,
                      actionLabel: 'Выбрать',
                      onTap: () => Navigator.of(context).pop(person),
                    ),
                    const SizedBox(height: 8),
                  ],
              ] else
                Text(
                  'Пригласите из Clover или добавьте только имя для слотов.',
                  style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
                ),
              if (state.pending.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Ожидают ответа',
                  style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final invite in state.pending) ...[
                  _StaffTile(
                    title: invite.title,
                    subtitle: invite.inviteeUsername?.trim().isNotEmpty == true
                        ? '@${invite.inviteeUsername}'
                        : 'Ожидает',
                    avatarUrl: invite.inviteeAvatarUrl,
                    actionLabel: 'Отменить',
                    outlined: true,
                    onTap: state.busy ? null : () => _cancelInvite(invite.id),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        BookingPrimaryButton(
          text: 'Пригласить из Clover',
          height: 48,
          isExpanded: true,
          onTap: () {
            setState(() => _mode = _SheetMode.invite);
            _cubit.search(_queryController.text);
          },
        ),
        const SizedBox(height: 8),
        AppOutlinedButton(
          text: 'Добавить только имя',
          height: 48,
          isExpanded: true,
          service: kBookingService,
          onTap: () => setState(() => _mode = _SheetMode.nameOnly),
        ),
      ],
    );
  }

  Widget _buildInvite(BuildContext context, BookingStaffSearchState state) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => setState(() => _mode = _SheetMode.pick),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  '← Назад',
                  style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        Text(
          'Отправим заявку в личный чат. После «Принять» можно назначить на услугу.',
          style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
        ),
        const SizedBox(height: 12),
        BookingField(
          controller: _queryController,
          hintText: 'Поиск по никнейму или имени',
          prefixIcon: AppIcons.searchRounded.icon,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 16),
        if (state.searchError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.searchError!,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ),
        Expanded(
          child: state.loadingSearch && state.results.isEmpty
              ? const BookingLoader(strokeWidth: 2)
              : state.results.isEmpty
                  ? Center(
                      child: Text(
                        'Никого не найдено',
                        style: AppTextStyle.base(14, color: colors.subTextColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final profile = state.results[index];
                        final status = _inviteStatusLabel(state, profile.id);
                        final locked = status != null || state.busy;
                        return _StaffTile(
                          title: profile.title,
                          subtitle: profile.displayName?.trim().isNotEmpty == true
                              ? profile.displayUsername
                              : null,
                          avatarUrl: profile.avatarUrl,
                          actionLabel: status ?? (state.busy ? '…' : 'Пригласить'),
                          outlined: status != null,
                          onTap: locked ? null : () => _invite(profile),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildNameOnly(BuildContext context, BookingStaffSearchState state) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => setState(() => _mode = _SheetMode.pick),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  '← Назад',
                  style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        Text(
          'Без аккаунта Clover — только имя в слотах. Календаря у исполнителя не будет.',
          style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              BookingField(
                controller: _nameController,
                hintText: 'Имя исполнителя',
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        BookingPrimaryButton(
          text: state.busy ? '…' : 'Добавить',
          height: 48,
          isExpanded: true,
          interactive: !state.busy,
          onTap: _createNameOnly,
        ),
      ],
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.title,
    required this.actionLabel,
    this.subtitle,
    this.avatarUrl,
    this.onTap,
    this.outlined = false,
  });

  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final String actionLabel;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.surfaceSoft,
                  backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Icon(AppIcons.user.icon, color: colors.iconMuted, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyle.base(13, color: colors.subTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (outlined)
              AppOutlinedButton(
                text: actionLabel,
                height: 40,
                isExpanded: true,
                service: kBookingService,
                onTap: onTap,
              )
            else
              BookingPrimaryButton(
                text: actionLabel,
                height: 40,
                borderRadius: 12,
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }
}
