import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/data/repository/booking_host_list_repository.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingListDetailPage extends StatefulWidget {
  const BookingListDetailPage({super.key, required this.item});

  final BookingListItem item;

  @override
  State<BookingListDetailPage> createState() => _BookingListDetailPageState();
}

class _BookingListDetailPageState extends State<BookingListDetailPage> {
  late final BookingHostListRepository _repository;
  late BookingListItem _item;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _repository = sl<BookingHostListRepository>();
    _item = widget.item;
  }

  bool get _hasChanges => _item.status != widget.item.status;

  void _popWithResult() {
    if (!mounted) return;
    // pop(), не maybePop — иначе PopScope с canPop:false блокирует выход после смены статуса.
    context.router.pop(_hasChanges ? _item : null);
  }

  Future<void> _applyStatus(BookingStatus status) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      await _repository.updateBookingStatus(_item.id, status);
      if (!mounted) return;
      setState(() {
        _item = _item.copyWith(status: status);
        _isUpdating = false;
      });
      AppSnackBar.show(context, message: 'Статус обновлён', kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: BookingException.from(e).userMessage, kind: AppSnackBarKind.error);
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _markStatus(BookingStatus status) => _applyStatus(status);

  Future<void> _revertStatus() async {
    if (_isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Отменить последний шаг?',
          style: AppTextStyle.base(18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Запись вернётся на предыдущий этап. Например, если случайно отметили «Клиент пришёл».',
          style: AppTextStyle.base(14, color: AppColors.subTextColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Назад', style: AppTextStyle.base(14, color: AppColors.subTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Вернуть',
              style: AppTextStyle.base(14, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final status = await _repository.revertBookingStatus(_item.id);
      if (!mounted) return;
      setState(() {
        _item = _item.copyWith(status: status);
        _isUpdating = false;
      });
      AppSnackBar.show(context, message: 'Статус возвращён', kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: BookingException.from(e).userMessage, kind: AppSnackBarKind.error);
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleEmergencyAction(BookingHostEmergencyAction action) async {
    if (_isUpdating) return;

    final confirmed = await _confirmEmergencyAction(action);
    if (!confirmed || !mounted) return;

    final status = switch (action) {
      BookingHostEmergencyAction.complete => BookingStatus.completed,
      BookingHostEmergencyAction.cancel => BookingStatus.cancelled,
      BookingHostEmergencyAction.noShow => BookingStatus.noShow,
    };

    await _applyStatus(status);
  }

  Future<bool> _confirmEmergencyAction(BookingHostEmergencyAction action) async {
    final (title, message, confirmLabel) = switch (action) {
      BookingHostEmergencyAction.complete => (
        'Завершить визит?',
        'Запись будет закрыта как оказанная. Все этапы проставятся автоматически.',
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
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: AppTextStyle.base(18, fontWeight: FontWeight.w700)),
        content: Text(message, style: AppTextStyle.base(14, color: AppColors.subTextColor, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Назад', style: AppTextStyle.base(14, color: AppColors.subTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: AppTextStyle.base(
                14,
                fontWeight: FontWeight.w700,
                color: action == BookingHostEmergencyAction.cancel
                    ? AppColors.destructive
                    : AppColors.primary,
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
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popWithResult();
      },
      child: BookingScreenShell(
        title: 'Запись',
        compactBar: true,
        onBackTap: _popWithResult,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 0, 0, BookingScreenShell.scrollBottomGap(context)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: BookingListDetailBody(
              item: _item,
              isUpdatingVisit: _isUpdating,
              onMarkVisitStatus: _markStatus,
              onEmergencyAction: _handleEmergencyAction,
              onRevertVisit: _revertStatus,
            ),
          ),
        ),
      ),
    );
  }
}
