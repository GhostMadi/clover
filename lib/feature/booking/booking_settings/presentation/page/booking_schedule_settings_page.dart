import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_create/data/mock/booking_services_mock_data.dart';
import 'package:clover/feature/booking/booking_settings/data/mock/booking_schedule_settings_store.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/booking/booking_settings/presentation/widget/booking_schedule_settings_form.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingScheduleSettingsPage extends StatefulWidget {
  const BookingScheduleSettingsPage({super.key});

  @override
  State<BookingScheduleSettingsPage> createState() => _BookingScheduleSettingsPageState();
}

class _BookingScheduleSettingsPageState extends State<BookingScheduleSettingsPage> {
  late BookingScheduleSettings _settings = BookingScheduleSettingsStore.current;
  bool _submitting = false;

  Future<void> _save() async {
    if (!_settings.isValid || _submitting) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    BookingScheduleSettingsStore.save(_settings);
    AppSnackBar.show(context, message: 'Настройки сохранены', kind: AppSnackBarKind.success);
    context.router.maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BookingScreenShell(
      title: 'Настройки записи',
      compactBar: true,
      isLoading: _submitting,
      showSave: true,
      canSave: _settings.isValid,
      onSaveTap: _save,
      body: BookingScheduleSettingsForm(
        settings: _settings,
        executors: BookingServicesMockData.executors,
        enabled: !_submitting,
        onChanged: (value) => setState(() => _settings = value),
      ),
    );
  }
}
