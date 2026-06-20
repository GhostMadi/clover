import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/booking/booking_create/data/mock/booking_services_mock_data.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_service_card.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_services_empty_state.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingCreatePage extends StatefulWidget {
  const BookingCreatePage({super.key});

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  late List<BookingService> _items = List<BookingService>.from(BookingServicesMockData.items);

  Future<void> _openCreate() async {
    final created = await context.router.push<BookingService>(const BookingServiceCreateRoute());
    if (created != null && mounted) {
      setState(() => _items = [created, ..._items]);
    }
  }

  Future<void> _openEdit(BookingService service) async {
    final updated = await context.router.push<BookingService>(BookingServiceEditRoute(service: service));
    if (updated != null && mounted) {
      setState(() {
        _items = [
          for (final item in _items)
            if (item.id == updated.id) updated else item,
        ];
      });
    }
  }

  Future<void> _openSettings() async {
    await context.router.push<bool>(const BookingScheduleSettingsRoute());
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return BookingScreenShell(
      title: 'Мои услуги',
      compactBar: true,
      showSettings: true,
      onSettingsTap: _openSettings,
      showAdd: true,
      onAddTap: _openCreate,
      body: items.isEmpty
          ? const BookingServicesEmptyState()
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => BookingServiceCard(
                service: items[index],
                onTap: () => _openEdit(items[index]),
              ),
            ),
    );
  }
}
