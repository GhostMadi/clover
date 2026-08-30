import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/data/repository/my_bookings_repository.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_cancel_sheet.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_detail_body.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MyBookingDetailPage extends StatefulWidget {
  const MyBookingDetailPage({super.key, required this.item});

  final MyBookingItem item;

  @override
  State<MyBookingDetailPage> createState() => _MyBookingDetailPageState();
}

class _MyBookingDetailPageState extends State<MyBookingDetailPage> {
  late final MyBookingsRepository _repository;
  late MyBookingItem _item;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _repository = sl<MyBookingsRepository>();
    _item = widget.item;
  }

  Future<void> _cancelBooking() async {
    if (_isCancelling) return;

    if (!_item.canClientCancel) {
      AppSnackBar.show(
        context,
        message: 'Отменить запись уже нельзя — время визита наступило',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final reason = await showMyBookingCancelSheet(
      context,
      serviceTitle: _item.serviceTitle,
      hostDisplayName: _item.hostDisplayName,
    );
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await _repository.cancelBooking(_item.id);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Запись отменена', kind: AppSnackBarKind.success);
      context.router.maybePop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: BookingException.from(e).userMessage, kind: AppSnackBarKind.error);
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomGap = BookingScreenShell.scrollBottomGap(context);
    final showCancel = _item.showCancelAction;

    return BookingScreenShell(
      title: 'Запись',
      compactBar: true,
      isLoading: _isCancelling,
      showCancel: showCancel,
      cancelLabel: 'Отменить',
      cancelIcon: AppIcons.delete.icon,
      onCancelTap: _cancelBooking,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MyBookingDetailBody(item: _item),
            if (showCancel) ...[
              const SizedBox(height: 24),
              _CancelBookingButton(
                isLoading: _isCancelling,
                enabled: _item.canClientCancel,
                onTap: _cancelBooking,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CancelBookingButton extends StatelessWidget {
  const _CancelBookingButton({required this.isLoading, required this.enabled, required this.onTap});

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;

    return Material(
      color: active ? context.colors.functionalSoftRed : context.colors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: active ? onTap : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? context.colors.borderCardRed : context.colors.border),
          ),
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.delete.icon,
                      size: 20,
                      color: active ? context.colors.destructive : context.colors.subTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Отменить бронь',
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w700,
                        color: active ? context.colors.destructive : context.colors.subTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
