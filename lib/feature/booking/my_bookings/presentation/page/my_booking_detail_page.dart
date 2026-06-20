import 'package:auto_route/auto_route.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/booking/my_bookings/presentation/widget/my_booking_detail_body.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MyBookingDetailPage extends StatelessWidget {
  const MyBookingDetailPage({super.key, required this.item});

  final MyBookingItem item;

  @override
  Widget build(BuildContext context) {
    return BookingScreenShell(
      title: 'Запись',
      compactBar: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
        child: MyBookingDetailBody(item: item),
      ),
    );
  }
}
