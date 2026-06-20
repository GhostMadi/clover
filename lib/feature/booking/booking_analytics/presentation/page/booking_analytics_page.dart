import 'package:auto_route/auto_route.dart';
import 'package:clover/feature/booking/booking_analytics/data/mock/booking_analytics_mock_data.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_popular_services_section.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_period_picker.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_user_picker.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingAnalyticsPage extends StatefulWidget {
  const BookingAnalyticsPage({super.key});

  @override
  State<BookingAnalyticsPage> createState() => _BookingAnalyticsPageState();
}

class _BookingAnalyticsPageState extends State<BookingAnalyticsPage> {
  late DateTime _start;
  late DateTime _end;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _applyMonthPreset();
  }

  void _applyWeekPreset() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    setState(() {
      _end = end;
      _start = end.subtract(const Duration(days: 6));
    });
  }

  void _applyMonthPreset() {
    final now = DateTime.now();
    setState(() {
      _start = DateTime(now.year, now.month, 1);
      _end = DateTime(now.year, now.month, now.day);
    });
  }

  void _onStartChanged(DateTime value) {
    setState(() {
      _start = value;
      if (_end.isBefore(_start)) {
        _end = _start;
      }
    });
  }

  void _onEndChanged(DateTime value) {
    setState(() {
      _end = value;
      if (_start.isAfter(_end)) {
        _start = _end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = BookingAnalyticsMockData.forPeriod(
      start: _start,
      end: _end,
      userId: _selectedUserId,
    );
    final periodLabel = BookingAnalyticsMockData.formatPeriodLabel(_start, _end);
    final selectedUser = BookingAnalyticsMockData.userById(_selectedUserId);
    final userLabel = selectedUser == null ? null : 'Исполнитель: ${selectedUser.displayName}';

    return BookingScreenShell(
      title: 'Аналитика',
      compactBar: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingAnalyticsPeriodPicker(
              start: _start,
              end: _end,
              onStartChanged: _onStartChanged,
              onEndChanged: _onEndChanged,
              onWeekPreset: _applyWeekPreset,
              onMonthPreset: _applyMonthPreset,
            ),
            const SizedBox(height: 20),
            BookingAnalyticsUserPicker(
              users: BookingAnalyticsMockData.users,
              selectedUserId: _selectedUserId,
              onChanged: (value) => setState(() => _selectedUserId = value),
            ),
            const SizedBox(height: 20),
            BookingAnalyticsPopularServicesSection(
              periodLabel: periodLabel,
              totalBookings: result.totalBookings,
              services: result.popularServices,
              userLabel: userLabel,
            ),
          ],
        ),
      ),
    );
  }
}
