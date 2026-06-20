import 'package:auto_route/auto_route.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingListDetailPage extends StatelessWidget {
  const BookingListDetailPage({super.key, required this.item});

  final BookingListItem item;

  @override
  Widget build(BuildContext context) {
    return BookingScreenShell(
      title: 'Запись',
      compactBar: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, BookingScreenShell.scrollBottomGap(context)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: BookingListDetailBody(item: item),
        ),
      ),
    );
  }
}
