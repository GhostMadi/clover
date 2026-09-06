import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/cubit/my_booking_detail_cubit.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_cancel_sheet.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_detail_body.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_reschedule_sheet.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MyBookingDetailPage extends StatefulWidget {
  const MyBookingDetailPage({super.key, required this.item});

  final MyBookingItem item;

  @override
  State<MyBookingDetailPage> createState() => _MyBookingDetailPageState();
}

class _MyBookingDetailPageState extends State<MyBookingDetailPage> {
  late final MyBookingDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MyBookingDetailCubit>(param1: widget.item);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _cancelBooking() async {
    if (_cubit.state.isBusy) return;

    final item = _cubit.state.item;
    if (!item.canClientCancel) {
      AppSnackBar.show(
        context,
        message: 'Отменить запись уже нельзя — слишком близко к визиту',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final reason = await showMyBookingCancelSheet(
      context,
      serviceTitle: item.serviceTitle,
      hostDisplayName: item.hostDisplayName,
    );
    if (reason == null || !mounted) return;

    try {
      await _cubit.cancel();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Запись отменена',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _reschedule() async {
    if (_cubit.state.isBusy) return;

    final item = _cubit.state.item;
    if (!item.canClientReschedule) {
      AppSnackBar.show(
        context,
        message: 'Перенести запись уже нельзя — слишком близко к визиту',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    final hostId = item.hostId.trim();
    final serviceId = item.serviceId?.trim();
    final staffId = item.staffId?.trim();
    if (hostId.isEmpty ||
        serviceId == null ||
        serviceId.isEmpty ||
        staffId == null ||
        staffId.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Нельзя перенести: нет услуги, мастера или владельца записи',
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBookingDetailCubit, MyBookingDetailState>(
      bloc: _cubit,
      builder: (context, state) {
        final item = state.item;
        final bottomGap = BookingScreenShell.scrollBottomGap(context);
        final showCancel = item.showCancelAction;
        final showReschedule = item.canClientReschedule;

        return BookingScreenShell(
          title: 'Запись',
          compactBar: true,
          isLoading: state.isBusy,
          showCancel: showCancel,
          cancelLabel: 'Отменить',
          cancelIcon: AppIcons.delete.icon,
          onCancelTap: _cancelBooking,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyBookingDetailBody(item: item),
                if (showReschedule) ...[
                  const SizedBox(height: 16),
                  BookingPrimaryButton(
                    text: 'Перенести',
                    isExpanded: true,
                    onTap: _reschedule,
                  ),
                ],
                if (showCancel) ...[
                  const SizedBox(height: 12),
                  _CancelBookingButton(
                    isLoading: state.isBusy,
                    enabled: item.canClientCancel,
                    onTap: _cancelBooking,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CancelBookingButton extends StatelessWidget {
  const _CancelBookingButton({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;

    return Material(
      color: active
          ? context.colors.functionalSoftRed
          : context.colors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: active ? onTap : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? context.colors.borderCardRed
                  : context.colors.border,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.delete.icon,
                      size: 20,
                      color: active
                          ? context.colors.destructive
                          : context.colors.subTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Отменить бронь',
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? context.colors.destructive
                            : context.colors.subTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
