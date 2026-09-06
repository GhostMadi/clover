import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_services_cubit.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_service_card.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_services_empty_state.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_services_qa_checklist.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
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
        final items = state.maybeMap(loaded: (s) => s.services, orElse: () => const <BookingService>[]);
        final staff = state.maybeMap(loaded: (s) => s.staff, orElse: () => const <BookingServiceExecutor>[]);
        final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;
        final staffById = {for (final person in staff) person.id: person};

        Widget buildBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (items.isEmpty && !isLoading) {
                return RefreshIndicator(
                  onRefresh: _cubit.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                    children: [
                      const BookingServicesQaChecklist(),
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                      const BookingServicesEmptyState(),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const BookingServicesQaChecklist();
                    }
                    final service = items[index - 1];
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
              );
            },
          );
        }

        return BookingScreenShell(
          title: 'Мои услуги',
          compactBar: true,
          isLoading: isLoading || isRefreshing,
          showSettings: true,
          onSettingsTap: _openSettings,
          showAdd: true,
          onAddTap: _openCreate,
          body: buildBody(),
        );
      },
    );
  }
}
