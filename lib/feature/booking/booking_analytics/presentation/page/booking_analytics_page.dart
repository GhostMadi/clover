import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/feature/booking/booking_analytics/data/models/booking_analytics_user.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/cubit/booking_analytics_cubit.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_period_picker.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_popular_services_section.dart';
import 'package:clover/feature/booking/booking_analytics/presentation/widget/booking_analytics_user_picker.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingAnalyticsPage extends StatefulWidget {
  const BookingAnalyticsPage({super.key});

  @override
  State<BookingAnalyticsPage> createState() => _BookingAnalyticsPageState();
}

class _BookingAnalyticsPageState extends State<BookingAnalyticsPage> {
  late final BookingAnalyticsCubit _cubit;
  late DateTime _start;
  late DateTime _end;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingAnalyticsCubit>();
    _applyMonthPreset();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
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

  void _reload() {
    _cubit.load(start: _start, end: _end, staffId: _selectedUserId);
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

  String _formatPeriodLabel(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}.${start.month.toString().padLeft(2, '0')}.${start.year}';
    }
    return '${start.day}.${start.month.toString().padLeft(2, '0')}.${start.year} — '
        '${end.day}.${end.month.toString().padLeft(2, '0')}.${end.year}';
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
        final selectedUser = _selectedUserId == null
            ? null
            : users.where((u) => u.id == _selectedUserId).firstOrNull;
        final periodLabel = _formatPeriodLabel(_start, _end);
        final userLabel = selectedUser == null ? null : 'Исполнитель: ${selectedUser.displayName}';

        return BookingScreenShell(
          title: 'Аналитика',
          compactBar: true,
          isLoading: isLoading,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () => SingleChildScrollView(
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
                    users: users,
                    selectedUserId: _selectedUserId,
                    onChanged: (value) {
                      setState(() => _selectedUserId = value);
                      _reload();
                    },
                  ),
                  const SizedBox(height: 20),
                  if (result != null)
                    BookingAnalyticsPopularServicesSection(
                      periodLabel: periodLabel,
                      totalBookings: result.totalBookings,
                      services: result.popularServices,
                      userLabel: userLabel,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
