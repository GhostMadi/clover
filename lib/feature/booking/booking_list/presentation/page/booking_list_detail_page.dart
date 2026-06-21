import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/data/repository/booking_host_list_repository.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/booking/shared/data/booking_error.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
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
    context.router.maybePop(_hasChanges ? _item : null);
  }

  Future<void> _markStatus(BookingStatus status) async {
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
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _popWithResult();
      },
      child: BookingScreenShell(
        title: 'Запись',
        compactBar: true,
        isLoading: _isUpdating,
        onBackTap: _popWithResult,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 0, 0, BookingScreenShell.scrollBottomGap(context)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: BookingListDetailBody(
              item: _item,
              isUpdatingVisit: _isUpdating,
              onMarkVisitStatus: _markStatus,
            ),
          ),
        ),
      ),
    );
  }
}
