import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/booking_settings/presentation/cubit/booking_schedule_settings_cubit.dart';
import 'package:clover/feature/_booking_/booking_settings/presentation/widget/booking_schedule_settings_form.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingScheduleSettingsPage extends StatefulWidget {
  const BookingScheduleSettingsPage({super.key});

  @override
  State<BookingScheduleSettingsPage> createState() => _BookingScheduleSettingsPageState();
}

class _BookingScheduleSettingsPageState extends State<BookingScheduleSettingsPage> {
  late final BookingScheduleSettingsCubit _cubit;
  BookingScheduleSettings? _settings;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingScheduleSettingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null || !settings.isValid) return;

    final ok = await _cubit.save(settings);
    if (!mounted || !ok) return;

    AppSnackBar.show(context, message: 'Настройки сохранены', kind: AppSnackBarKind.success);
    context.router.maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingScheduleSettingsCubit, BookingScheduleSettingsState>(
      bloc: _cubit,
      listener: (context, state) {
        state.mapOrNull(loaded: (s) => _settings = s.settings);
      },
      builder: (context, state) {
        final isSubmitting = state.maybeMap(submitting: (_) => true, orElse: () => false);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false);
        final settings = _settings ?? state.maybeMap(loaded: (s) => s.settings, orElse: () => null);
        final staff = state.maybeMap(loaded: (s) => s.staff, orElse: () => const <BookingServiceExecutor>[]);

        return BookingScreenShell(
          title: 'Настройки записи',
          compactBar: true,
          isLoading: isSubmitting || isLoading,
          showSave: true,
          canSave: settings?.isValid == true && !isSubmitting,
          onSaveTap: _save,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (settings == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return BookingScheduleSettingsForm(
                settings: settings,
                executors: staff,
                enabled: !isSubmitting,
                onChanged: (value) => setState(() => _settings = value),
              );
            },
          ),
        );
      },
    );
  }
}
