import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_invite.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_staff_search_cubit.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pick linked staff for a service, invite Clover account, or add name-only.
abstract final class BookingStaffProfileSearchSheet {
  static Future<BookingServiceExecutor?> show(
    BuildContext context, {
    Set<String> excludeStaffIds = const {},
    Set<String> excludeProfileIds = const {},
  }) {
    return AppBottomSheet.show<BookingServiceExecutor>(
      service: kBookingService,
      context: context,
      title: 'Исполнители',
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _Body(
        excludeStaffIds: excludeStaffIds,
        excludeProfileIds: excludeProfileIds,
      ),
    );
  }
}

enum _SheetMode { pick, invite, nameOnly }

class _Body extends StatefulWidget {
  const _Body({
    required this.excludeStaffIds,
    required this.excludeProfileIds,
  });

  final Set<String> excludeStaffIds;
  final Set<String> excludeProfileIds;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final BookingStaffSearchCubit _searchCubit;
  late final TextEditingController _queryController;
  late final TextEditingController _nameController;
  late final BookingStaffRepository _repository;

  _SheetMode _mode = _SheetMode.pick;
  List<BookingServiceExecutor> _staff = const [];
  List<BookingStaffInvite> _pending = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = sl<BookingStaffRepository>();
    _searchCubit = sl<BookingStaffSearchCubit>()
      ..configure(excludeProfileIds: {
        ...widget.excludeProfileIds,
      });
    _queryController = TextEditingController();
    _nameController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    _reload();
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _nameController.dispose();
    _searchCubit.close();
    super.dispose();
  }

  void _onQueryChanged() {
    if (_mode == _SheetMode.invite) {
      _searchCubit.search(_queryController.text);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.listMyStaff(),
        _repository.listPendingInvites(),
      ]);
      if (!mounted) return;
      setState(() {
        _staff = results[0] as List<BookingServiceExecutor>;
        _pending = results[1] as List<BookingStaffInvite>;
        _loading = false;
      });
      // Не прячем из поиска — показываем статус «Приглашён» / «В команде».
      _searchCubit.configure(excludeProfileIds: widget.excludeProfileIds);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BookingException.from(e).userMessage;
      });
    }
  }

  Future<void> _invite(BookingStaffProfile profile) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.inviteStaff(profile.id);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Приглашение отправлено в чат',
        kind: AppSnackBarKind.success,
      );
      await _reload();
      if (!mounted) return;
      setState(() => _mode = _SheetMode.pick);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelInvite(String inviteId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.cancelInvite(inviteId);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Заявка отменена', kind: AppSnackBarKind.success);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createNameOnly() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final staff = await _repository.createStaff(displayName: name);
      if (!mounted) return;
      Navigator.of(context).pop(staff);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
      setState(() => _busy = false);
    }
  }

  List<BookingServiceExecutor> get _availableStaff {
    return [
      for (final person in _staff)
        if (!widget.excludeStaffIds.contains(person.id)) person,
    ];
  }

  String? _inviteStatusLabel(String profileId) {
    final id = profileId.trim();
    if (id.isEmpty) return null;
    if (_staff.any((s) => s.profileId?.trim() == id)) return 'В команде';
    if (_pending.any((i) => i.inviteeId.trim() == id)) return 'Приглашён';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BookingLoader(strokeWidth: 2);
    }

    return switch (_mode) {
      _SheetMode.pick => _buildPick(context),
      _SheetMode.invite => _buildInvite(context),
      _SheetMode.nameOnly => _buildNameOnly(context),
    };
  }

  Widget _buildPick(BuildContext context) {
    final available = _availableStaff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: context.colors.subTextColor),
            ),
          ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                'Уже в команде',
                style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (available.isEmpty)
                Text(
                  'Пока никого нет — пригласите аккаунт Clover или добавьте имя.',
                  style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
                )
              else
                ...[
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
                ],
              if (_pending.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Ожидают ответа',
                  style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final invite in _pending) ...[
                  _StaffTile(
                    title: invite.title,
                    subtitle: invite.inviteeUsername?.trim().isNotEmpty == true
                        ? '@${invite.inviteeUsername}'
                        : 'Ожидает',
                    avatarUrl: invite.inviteeAvatarUrl,
                    actionLabel: 'Отменить',
                    outlined: true,
                    onTap: _busy ? null : () => _cancelInvite(invite.id),
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
            _searchCubit.search(_queryController.text);
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

  Widget _buildInvite(BuildContext context) {
    return BlocProvider.value(
      value: _searchCubit,
      child: BlocBuilder<BookingStaffSearchCubit, BookingStaffSearchState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _mode = _SheetMode.pick),
                  child: Text(
                    '← Назад',
                    style: AppTextStyle.base(14, color: context.colors.subTextColor),
                  ),
                ),
              ),
              Text(
                'Отправим заявку в личный чат. После «Принять» можно назначить на услугу.',
                style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 12),
              BookingField(
                controller: _queryController,
                hintText: 'Поиск по никнейму или имени',
                prefixIcon: AppIcons.searchRounded.icon,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(13, color: context.colors.subTextColor),
                  ),
                ),
              Expanded(
                child: state.loading && state.results.isEmpty
                    ? const BookingLoader(strokeWidth: 2)
                    : state.results.isEmpty
                        ? Center(
                            child: Text(
                              'Никого не найдено',
                              style: AppTextStyle.base(14, color: context.colors.subTextColor),
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final profile = state.results[index];
                              final status = _inviteStatusLabel(profile.id);
                              final locked = status != null || _busy;
                              return _StaffTile(
                                title: profile.title,
                                subtitle: profile.displayName?.trim().isNotEmpty == true
                                    ? profile.displayUsername
                                    : null,
                                avatarUrl: profile.avatarUrl,
                                actionLabel: status ?? (_busy ? '…' : 'Пригласить'),
                                outlined: status != null,
                                onTap: locked ? null : () => _invite(profile),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNameOnly(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _mode = _SheetMode.pick),
            child: Text(
              '← Назад',
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
          ),
        ),
        Text(
          'Без аккаунта Clover — только имя в слотах. Календаря у исполнителя не будет.',
          style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
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
          text: _busy ? '…' : 'Добавить',
          height: 48,
          isExpanded: true,
          interactive: !_busy,
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
    final url = avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
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
                  backgroundColor: context.colors.surfaceSoft,
                  backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Icon(AppIcons.user.icon, color: context.colors.iconMuted, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyle.base(13, color: context.colors.subTextColor),
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
