import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_booking_/booking_calendar/presentation/cubit/booking_calendar_hosts_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Аккаунты, которые дают заказы текущему пользователю как исполнителю.
@RoutePage()
class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  late final BookingCalendarHostsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingCalendarHostsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final bottomGap = BookingScreenShell.scrollBottomGap(context);

    return BlocBuilder<BookingCalendarHostsCubit, BookingCalendarHostsState>(
      bloc: _cubit,
      builder: (context, state) {
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false);

        return BookingScreenShell(
          title: 'Календарь заказов',
          compactBar: true,
          isLoading: isLoading,
          body: state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message)),
            loaded: (hosts) {
              if (hosts.isEmpty) {
                return const Center(
                  child: BookingListEmptyState(
                    title: 'Пока нет источников',
                    subtitle:
                        'Когда вас добавят исполнителем в запись другого аккаунта, он появится здесь',
                    showCreateButton: false,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
                  itemCount: hosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final host = hosts[index];
                    final subtitle = [
                      if (host.hostUsernameLabel.isNotEmpty) host.hostUsernameLabel,
                      if (!host.isActive) 'неактивен',
                    ].join(' · ');

                    return AppTile(
                      title: host.hostDisplayName.trim().isEmpty
                          ? (host.hostUsernameLabel.isEmpty ? 'Аккаунт' : host.hostUsernameLabel)
                          : host.hostDisplayName,
                      subtitle: subtitle.isEmpty ? 'Заказы для вас' : subtitle,
                      icon: AppIcons.calendarToday.icon,
                      iconColor: accent.icon,
                      iconBackgroundColor: accent.soft,
                      showChevron: true,
                      onTap: () {
                        context.router.push(
                          BookingCalendarHostRoute(
                            hostId: host.hostId,
                            hostTitle: host.hostDisplayName.trim().isEmpty
                                ? host.hostUsernameLabel
                                : host.hostDisplayName,
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
