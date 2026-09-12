import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_points_prefs.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingPointHubPage extends StatefulWidget {
  const BookingPointHubPage({
    super.key,
    required this.pointId,
    this.pointName,
  });

  final String pointId;
  final String? pointName;

  @override
  State<BookingPointHubPage> createState() => _BookingPointHubPageState();
}

class _BookingPointHubPageState extends State<BookingPointHubPage> {
  String _title = 'Точка';
  var _loading = true;
  var _missing = false;

  @override
  void initState() {
    super.initState();
    final hint = widget.pointName?.trim();
    if (hint != null && hint.isNotEmpty) _title = hint;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = sl<BookingPointsPrefs>();
    await prefs.writeLastPointId(widget.pointId);

    final point = await sl<BookingPointsRepository>().getPoint(widget.pointId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (point == null) {
        _missing = true;
      } else {
        _title = point.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final pointId = widget.pointId;

    if (_loading) {
      return BookingScreenShell(
        title: _title,
        body: const BookingLoader(),
      );
    }

    if (_missing) {
      return BookingScreenShell(
        title: 'Точка',
        body: Center(
          child: Text(
            'Точка не найдена',
            style: AppTextStyle.base(15, color: context.colors.subTextColor),
          ),
        ),
      );
    }

    return BookingScreenShell(
      title: _title,
      pointId: pointId,
      onPointChanged: (nextId) {
        context.router.replace(
          BookingPointHubRoute(pointId: nextId),
        );
      },
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Точка'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Мои записи',
                  subtitle: 'Календарь и визиты',
                  icon: AppIcons.calendarMonth.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(BookingListRoute(pointId: pointId)),
                ),
                AppTile(
                  title: 'Услуги',
                  subtitle: 'Цены, длительность, исполнители',
                  icon: AppIcons.designServices.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(BookingCreateRoute(pointId: pointId)),
                ),
                AppTile(
                  title: 'Аналитика',
                  subtitle: 'Записи, услуги и исполнители',
                  icon: AppIcons.insights.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(BookingAnalyticsRoute(pointId: pointId)),
                ),
                AppTile(
                  title: 'Настройки расписания',
                  subtitle: 'Часы работы, горизонт, отсутствия',
                  icon: AppIcons.settingsOutlined.icon,
                  iconColor: accent.icon,
                  iconBackgroundColor: accent.soft,
                  showChevron: true,
                  onTap: () => context.router.push(
                    BookingScheduleSettingsRoute(pointId: pointId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
