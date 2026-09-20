import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/models/booking_analytics_user.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/cubit/booking_analytics_cubit.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/widget/booking_analytics_period_picker.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/widget/booking_analytics_popular_services_section.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/widget/booking_analytics_summary_section.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/widget/booking_analytics_top_staff_section.dart';
import 'package:clover/feature/_booking_/booking_analytics/presentation/widget/booking_analytics_user_picker.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_point_title.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingAnalyticsPage extends StatefulWidget {
  const BookingAnalyticsPage({super.key, required this.pointId});

  final String pointId;

  @override
  State<BookingAnalyticsPage> createState() => _BookingAnalyticsPageState();
}

class _BookingAnalyticsPageState extends State<BookingAnalyticsPage> {
  late final BookingAnalyticsCubit _cubit;
  late DateTime _start;
  late DateTime _end;
  String? _selectedUserId;
  String _title = 'Аналитика';

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingAnalyticsCubit>();
    _applyMonthPreset();
    _resolveTitle();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _resolveTitle() async {
    final name = await resolveBookingPointNameCached(widget.pointId);
    if (!mounted || name == null) return;
    setState(() => _title = name);
  }

  void _onPointChanged(String nextId) {
    context.router.replace(BookingAnalyticsRoute(pointId: nextId));
  }

  void _applyWeekPreset() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    setState(() {
      _end = end;
      _start = end.subtract(const Duration(days: 6));
    });
    _reload();
  }

  void _applyMonthPreset() {
    final now = DateTime.now();
    setState(() {
      _start = DateTime(now.year, now.month, 1);
      _end = DateTime(now.year, now.month, now.day);
    });
    _reload();
  }

  Future<void> _reload() {
    return _cubit.load(
      start: _start,
      end: _end,
      staffId: _selectedUserId,
      pointId: widget.pointId,
    );
  }

  void _onStartChanged(DateTime value) {
    setState(() {
      _start = value;
      if (_end.isBefore(_start)) _end = _start;
    });
    _reload();
  }

  void _onEndChanged(DateTime value) {
    setState(() {
      _end = value;
      if (_start.isAfter(_end)) _start = _end;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingAnalyticsCubit, BookingAnalyticsState>(
      bloc: _cubit,
      builder: (context, state) {
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false);
        final result = state.maybeMap(loaded: (s) => s.result, orElse: () => null);
        final staff = state.maybeMap(loaded: (s) => s.staff, orElse: () => const []);
        final users = [
          for (final member in staff)
            BookingAnalyticsUser(
              id: member.id,
              displayName: member.displayName,
              username: member.username,
            ),
        ];

        return BookingScreenShell(
          title: _title,
          pointId: widget.pointId,
          onPointChanged: _onPointChanged,
          compactBar: true,
          isLoading: isLoading && result == null,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () => RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    if (users.length > 1) ...[
                      const SizedBox(height: 12),
                      BookingAnalyticsUserPicker(
                        users: users,
                        selectedUserId: _selectedUserId,
                        onChanged: (value) {
                          setState(() => _selectedUserId = value);
                          _reload();
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (result != null) ...[
                      BookingAnalyticsSummarySection(result: result),
                      if (result.popularServices.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        BookingAnalyticsPopularServicesSection(services: result.popularServices),
                      ],
                      if (result.topStaff.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        BookingAnalyticsTopStaffSection(staff: result.topStaff),
                      ],
                      if (result.totalBookings == 0) ...[
                        const SizedBox(height: 24),
                        Text(
                          'За период записей нет',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: context.colors.subTextColor),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
