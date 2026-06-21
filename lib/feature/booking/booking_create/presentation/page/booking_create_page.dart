import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/presentation/cubit/booking_services_cubit.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_service_card.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_services_empty_state.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingCreatePage extends StatefulWidget {
  const BookingCreatePage({super.key});

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  late final BookingServicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingServicesCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final created = await context.router.push<BookingService>(const BookingServiceCreateRoute());
    if (created != null && mounted) {
      await _cubit.refresh();
    }
  }

  Future<void> _openEdit(BookingService service) async {
    final updated = await context.router.push<BookingService>(BookingServiceEditRoute(service: service));
    if (updated != null && mounted) {
      await _cubit.refresh();
    }
  }

  Future<void> _openSettings() async {
    final saved = await context.router.push<bool>(const BookingScheduleSettingsRoute());
    if (saved == true && mounted) {
      await _cubit.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingServicesCubit, BookingServicesState>(
      bloc: _cubit,
      builder: (context, state) {
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false);
        final items = state.maybeMap(loaded: (s) => s.services, orElse: () => const <BookingService>[]);
        final staff = state.maybeMap(loaded: (s) => s.staff, orElse: () => const <BookingServiceExecutor>[]);
        final staffById = {for (final person in staff) person.id: person};

        return BookingScreenShell(
          title: 'Мои услуги',
          compactBar: true,
          isLoading: isLoading,
          showSettings: true,
          onSettingsTap: _openSettings,
          showAdd: true,
          onAddTap: _openCreate,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () => items.isEmpty
                ? const BookingServicesEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final service = items[index];
                      final executors = [
                        for (final id in service.executorIds)
                          if (staffById[id] != null) staffById[id]!,
                      ];
                      return BookingServiceCard(
                        service: service,
                        executors: executors,
                        onTap: () => _openEdit(service),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
