import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

Future<BookingPoint?> showBookingPointSwitcherSheet({
  required BuildContext context,
  required String currentPointId,
}) {
  return AppBottomSheet.show<BookingPoint>(
    context: context,
    title: 'Точка',
    contentHeight: 320,
    content: _BookingPointSwitcherBody(currentPointId: currentPointId),
    service: kBookingService,
  );
}

class _BookingPointSwitcherBody extends StatefulWidget {
  const _BookingPointSwitcherBody({required this.currentPointId});

  final String currentPointId;

  @override
  State<_BookingPointSwitcherBody> createState() => _BookingPointSwitcherBodyState();
}

class _BookingPointSwitcherBodyState extends State<_BookingPointSwitcherBody> {
  List<BookingPoint>? _points;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await sl<BookingPointsRepository>().listMyPoints();
      if (!mounted) return;
      setState(() => _points = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final points = _points;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, style: AppTextStyle.base(14, color: context.colors.destructive)),
      );
    }
    if (points == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: points.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.divider),
      itemBuilder: (context, index) {
        final point = points[index];
        final active = point.id == widget.currentPointId;
        return ListTile(
          title: Text(
            point.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(
              15,
              color: context.colors.textColor,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: active
              ? Icon(AppIcons.checkRounded.icon, color: accent.icon, size: 20)
              : null,
          onTap: () => Navigator.of(context).pop(point),
        );
      },
    );
  }
}
