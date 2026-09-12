import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_booking_/booking_points/presentation/cubit/booking_points_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Список точек хозяина (вход Settings → Запись). Как посещаемость: list → hub.
@RoutePage()
class SettingsBookingPage extends StatefulWidget {
  const SettingsBookingPage({super.key});

  @override
  State<SettingsBookingPage> createState() => _SettingsBookingPageState();
}

class _SettingsBookingPageState extends State<SettingsBookingPage> {
  late final BookingPointsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingPointsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openPoint(String pointId, {required String name}) async {
    await _cubit.remember(pointId);
    if (!mounted) return;
    await context.router.push(BookingPointHubRoute(pointId: pointId, pointName: name));
  }

  Future<void> _createPoint() async {
    final nameController = TextEditingController(text: 'Основная');
    try {
      final name = await AppBottomSheet.show<String>(
        context: context,
        title: 'Новая точка',
        content: BookingField(
          controller: nameController,
          labelText: 'Название',
          textInputAction: TextInputAction.done,
        ),
        actions: [
          BookingPrimaryButton(
            text: 'Создать',
            isExpanded: true,
            onTap: () {
              final value = nameController.text.trim();
              if (value.isEmpty) return;
              Navigator.of(context).pop(value);
            },
          ),
        ],
      );
      if (name == null || name.isEmpty || !mounted) return;

      final point = await _cubit.create(name);
      if (!mounted) return;
      if (point == null) {
        AppSnackBar.show(
          context,
          message: 'Не удалось создать точку',
          kind: AppSnackBarKind.error,
        );
        return;
      }
      await _openPoint(point.id, name: point.name);
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), nameController.dispose);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return BlocBuilder<BookingPointsCubit, BookingPointsState>(
      bloc: _cubit,
      builder: (context, state) {
        final points = state is BookingPointsLoaded ? state.points : const [];
        final loading = state is BookingPointsLoading || state is BookingPointsInitial;

        return SettingsScreenShell(
          title: 'Запись',
          service: kBookingService,
          body: loading
              ? const BookingLoader()
              : state is BookingPointsError
                  ? Center(
                      child: Text(
                        state.message,
                        style: AppTextStyle.base(15, color: context.colors.subTextColor),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cubit.load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          const SettingsTileSectionTitle('Точки'),
                          AppTileGroup(
                            children: [
                              for (final point in points)
                                AppTile(
                                  title: point.name,
                                  subtitle: 'Услуги, расписание, записи',
                                  icon: AppIcons.locationOn.icon,
                                  iconColor: accent.icon,
                                  iconBackgroundColor: accent.soft,
                                  showChevron: true,
                                  onTap: () => _openPoint(point.id, name: point.name),
                                ),
                              AppTile(
                                title: 'Новая точка',
                                subtitle: 'Салон, филиал или кабинет',
                                icon: AppIcons.add.icon,
                                iconColor: accent.icon,
                                iconBackgroundColor: accent.soft,
                                showChevron: false,
                                onTap: _createPoint,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
