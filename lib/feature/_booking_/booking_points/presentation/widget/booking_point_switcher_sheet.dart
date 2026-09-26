import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/booking_points/presentation/cubit/booking_points_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clover/core/extension/context.dart';

Future<BookingPoint?> showBookingPointSwitcherSheet({
  required BuildContext context,
  required String currentPointId,
  List<BookingPoint>? initialPoints,
}) {
  return AppBottomSheet.show<BookingPoint>(
    context: context,
    title: context.l10n.booking_point,
    contentHeight: 320,
    content: _BookingPointSwitcherBody(
      currentPointId: currentPointId,
      initialPoints: initialPoints,
    ),
    service: kBookingService,
  );
}

class _BookingPointSwitcherBody extends StatefulWidget {
  const _BookingPointSwitcherBody({
    required this.currentPointId,
    this.initialPoints,
  });

  final String currentPointId;
  final List<BookingPoint>? initialPoints;

  @override
  State<_BookingPointSwitcherBody> createState() => _BookingPointSwitcherBodyState();
}

class _BookingPointSwitcherBodyState extends State<_BookingPointSwitcherBody> {
  late final BookingPointsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingPointsCubit>();
    final seeded = widget.initialPoints;
    if (seeded != null && seeded.isNotEmpty) {
      _cubit.emitSeeded(seeded);
      _cubit.refresh();
    } else {
      _cubit.load();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return BlocBuilder<BookingPointsCubit, BookingPointsState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is BookingPointsError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(state.message, style: AppTextStyle.base(14, color: context.colors.destructive)),
          );
        }

        final loaded = state is BookingPointsLoaded ? state : null;
        final points = loaded?.points;

        if (points == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: BookingLoader(size: 28),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          itemCount: points.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.divider),
          itemBuilder: (context, index) {
            final point = points[index];
            final selected = point.id == widget.currentPointId;
            return ListTile(
              title: Text(
                point.name,
                style: AppTextStyle.base(
                  16,
                  color: context.colors.textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? Icon(AppIcons.checkRounded.icon, color: accent.icon, size: 20)
                  : null,
              onTap: () => Navigator.of(context).pop(point),
            );
          },
        );
      },
    );
  }
}
