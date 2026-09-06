import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/session/app_session.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/cubit/booking_list_detail_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_reschedule_sheet.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingListDetailPage extends StatefulWidget {
  const BookingListDetailPage({super.key, required this.item});

  final BookingListItem item;

  @override
  State<BookingListDetailPage> createState() => _BookingListDetailPageState();
}

class _BookingListDetailPageState extends State<BookingListDetailPage> {
  late final BookingListDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingListDetailCubit>(param1: widget.item);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _popWithResult() {
    if (!mounted) return;
    // pop(), не maybePop — иначе PopScope с canPop:false блокирует выход после смены статуса.
    context.router.pop(_cubit.hasChanges ? _cubit.state.item : null);
  }

  Future<void> _applyStatus(BookingStatus status) async {
    if (_cubit.state.isUpdating) return;

    try {
      await _cubit.applyStatus(status);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Статус обновлён',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _markStatus(BookingStatus status) => _applyStatus(status);

  Future<void> _revertStatus() async {
    if (_cubit.state.isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Отменить последний шаг?',
          style: AppTextStyle.base(18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Запись вернётся на предыдущий этап. Например, если случайно отметили «Клиент пришёл».',
          style: AppTextStyle.base(
            14,
            color: context.colors.subTextColor,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Назад',
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Вернуть',
              style: AppTextStyle.base(
                14,
                fontWeight: FontWeight.w700,
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _cubit.revertStatus();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Статус возвращён',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _handleEmergencyAction(BookingHostEmergencyAction action) async {
    if (_cubit.state.isUpdating) return;

    if (action == BookingHostEmergencyAction.reschedule) {
      await _reschedule();
      return;
    }

    final confirmed = await _confirmEmergencyAction(action);
    if (!confirmed || !mounted) return;

    final status = switch (action) {
      BookingHostEmergencyAction.complete => BookingStatus.completed,
      BookingHostEmergencyAction.cancel => BookingStatus.cancelled,
      BookingHostEmergencyAction.noShow => BookingStatus.noShow,
      BookingHostEmergencyAction.reschedule => null,
    };
    if (status == null) return;

    await _applyStatus(status);
  }

  Future<void> _reschedule() async {
    final item = _cubit.state.item;
    final hostId = sl<AppSession>().userId?.trim();
    final serviceId = item.serviceId?.trim();
    final staffId = item.staffId?.trim();
    if (hostId == null || hostId.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Нельзя перенести: сессия не найдена. Войдите снова.',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    if (serviceId == null ||
        serviceId.isEmpty ||
        staffId == null ||
        staffId.isEmpty) {
      AppSnackBar.show(
        context,
        message:
            'Нельзя перенести: нет услуги или исполнителя. Обновите список записей.',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final current = item.startsAtDate ?? DateTime.now();

    final picked = await AppBottomSheet.show<DateTime>(
      context: context,
      title: 'Перенести запись',
      service: kBookingService,
      contentHeight: 420,
      content: BookingRescheduleSheet(
        hostId: hostId,
        serviceId: serviceId,
        staffId: staffId,
        bookingId: item.id,
        initialDay: current,
      ),
    );

    if (picked == null || !mounted) return;

    try {
      await _cubit.reschedule(staffId: staffId, startsAt: picked);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Запись перенесена',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<bool> _confirmEmergencyAction(
    BookingHostEmergencyAction action,
  ) async {
    final (title, message, confirmLabel) = switch (action) {
      BookingHostEmergencyAction.complete => (
        'Завершить визит?',
        'Только вы закрываете услугу как оказанную. Система сама этого не делает.',
        'Завершить',
      ),
      BookingHostEmergencyAction.cancel => (
        'Отменить визит?',
        'Слот освободится. Отменить можно в любой момент, даже если услуга уже началась.',
        'Отменить',
      ),
      BookingHostEmergencyAction.noShow => (
        'Клиент не пришёл?',
        'Запись будет закрыта, слот освободится для других клиентов.',
        'Подтвердить',
      ),
      BookingHostEmergencyAction.reschedule => ('', '', ''),
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: AppTextStyle.base(18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: AppTextStyle.base(
            14,
            color: context.colors.subTextColor,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Назад',
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: AppTextStyle.base(
                14,
                fontWeight: FontWeight.w700,
                color: action == BookingHostEmergencyAction.cancel
                    ? context.colors.destructive
                    : context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingListDetailCubit, BookingListDetailState>(
      bloc: _cubit,
      builder: (context, state) {
        return PopScope(
          canPop: !_cubit.hasChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _popWithResult();
          },
          child: BookingScreenShell(
            title: 'Запись',
            compactBar: true,
            onBackTap: _popWithResult,
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                BookingScreenShell.scrollBottomGap(context),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BookingListDetailBody(
                  item: state.item,
                  isUpdatingVisit: state.isUpdating,
                  onMarkVisitStatus: _markStatus,
                  onEmergencyAction: _handleEmergencyAction,
                  onRevertVisit: _revertStatus,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
