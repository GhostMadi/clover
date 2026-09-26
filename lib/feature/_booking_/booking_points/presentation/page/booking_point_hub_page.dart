import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_points/presentation/cubit/booking_points_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/booking_point_chat_nav.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_hub_nav_card.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

@RoutePage()
class BookingPointHubPage extends StatefulWidget {
  const BookingPointHubPage({super.key, required this.pointId, this.pointName});

  final String pointId;
  final String? pointName;

  @override
  State<BookingPointHubPage> createState() => _BookingPointHubPageState();
}

class _BookingPointHubPageState extends State<BookingPointHubPage> {
  late final BookingPointsCubit _pointsCubit;
  late String _title;
  late bool _loading;
  var _missing = false;

  @override
  void initState() {
    super.initState();
    _pointsCubit = sl<BookingPointsCubit>();
    final hint = widget.pointName?.trim();
    final hasHint = hint != null && hint.isNotEmpty;
    _title = hasHint ? hint : context.l10n.booking_point;
    _loading = !hasHint;
    _bootstrap();
  }

  @override
  void dispose() {
    _pointsCubit.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final pointId = widget.pointId.trim();
    await _pointsCubit.remember(pointId);

    final hint = widget.pointName?.trim();
    if (hint != null && hint.isNotEmpty) {
      if (mounted && (_loading || _title != hint)) {
        setState(() {
          _loading = false;
          _missing = false;
          _title = hint;
        });
      }
      return;
    }

    final name = await _pointsCubit.resolvePointName(pointId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (name == null || name.isEmpty) {
        _missing = true;
      } else {
        _title = name;
      }
    });
  }

  Future<void> _onPointChanged(String nextId) async {
    final name = await _pointsCubit.resolvePointName(nextId);
    if (!mounted) return;
    context.router.replace(BookingPointHubRoute(pointId: nextId, pointName: name));
  }

  @override
  Widget build(BuildContext context) {
    final pointId = widget.pointId;

    if (_loading) {
      return BookingScreenShell(title: _title, compactBar: true, body: const BookingLoader());
    }

    if (_missing) {
      return BookingScreenShell(
        title: context.l10n.booking_point,
        compactBar: true,
        body: Center(
          child: Text(context.l10n.booking_point_not_found, style: AppTextStyle.base(15, color: context.colors.subTextColor)),
        ),
      );
    }

    return BookingScreenShell(
      title: _title,
      pointId: pointId,
      compactBar: true,
      onPointChanged: _onPointChanged,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, BookingScreenShell.scrollBottomGap(context)),
        child: BookingHubNavGrid(
          children: [
            BookingHubNavCard(
              title: context.l10n.booking_my_bookings,
              subtitle: context.l10n.booking_my_bookings_subtitle,
              icon: AppIcons.calendarMonth.icon,
              onTap: () => context.router.push(BookingListRoute(pointId: pointId)),
            ),
            BookingHubNavCard(
              title: context.l10n.booking_services_label,
              subtitle: context.l10n.booking_services_subtitle,
              icon: AppIcons.designServices.icon,
              onTap: () => context.router.push(BookingCreateRoute(pointId: pointId)),
            ),
            BookingHubNavCard(
              title: context.l10n.booking_team,
              subtitle: context.l10n.booking_team_subtitle,
              icon: AppIcons.groupOutlined.icon,
              onTap: () => context.router.push(BookingTeamRoute(pointId: pointId)),
            ),
            BookingHubNavCard(
              title: context.l10n.booking_chat_title,
              subtitle: context.l10n.booking_chat_subtitle,
              icon: AppIcons.chat.icon,
              onTap: () => openBookingPointChat(
                context,
                pointId: pointId,
                pointName: _title,
              ),
            ),
            BookingHubNavCard(
              title: context.l10n.booking_analytics_label,
              subtitle: context.l10n.booking_analytics_subtitle,
              icon: AppIcons.insights.icon,
              onTap: () => context.router.push(BookingAnalyticsRoute(pointId: pointId)),
            ),
            BookingHubNavCard(
              title: context.l10n.booking_schedule,
              subtitle: context.l10n.booking_schedule_subtitle,
              icon: AppIcons.settingsOutlined.icon,
              onTap: () => context.router.push(BookingScheduleSettingsRoute(pointId: pointId)),
            ),
          ],
        ),
      ),
    );
  }
}
