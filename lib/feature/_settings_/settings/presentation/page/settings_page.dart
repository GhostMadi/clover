import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = bookingServiceAccent(context.colors);
    final attendance = attendanceServiceAccent(context.colors);
    final resources = context.colors.serviceAccent(kResourcesService);

    return SettingsScreenShell(
      title: 'Настройки',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTileSectionTitle('Сервисы'),
            BlocBuilder<ProfileCubit, ProfileState>(
              bloc: sl<ProfileCubit>(),
              builder: (context, state) {
                final hasBooking = state.mapOrNull(loaded: (s) => s.profile.hasBookingTag) ?? false;
                return AppTileGroup(
                  children: [
                    if (hasBooking)
                      AppTile(
                        title: 'Запись',
                        subtitle: 'Услуги, inbox и расписание',
                        icon: AppIcons.calendarMonth.icon,
                        iconColor: booking.icon,
                        iconBackgroundColor: booking.soft,
                        showChevron: true,
                        onTap: () => context.router.push(const SettingsBookingRoute()),
                      ),
                    AppTile(
                      title: 'Посещаемость',
                      subtitle: 'Кнопка в профиле и настройки сервиса',
                      icon: AppIcons.schedule.icon,
                      iconColor: attendance.icon,
                      iconBackgroundColor: attendance.soft,
                      showChevron: true,
                      onTap: () => context.router.push(const SettingsAttendanceRoute()),
                    ),
                    AppTile(
                      title: 'Ресурсы',
                      icon: AppIcons.inventory.icon,
                      iconColor: resources.icon,
                      iconBackgroundColor: resources.soft,
                      showChevron: true,
                      onTap: () => context.router.push(const SettingsResourcesRoute()),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('Архивы'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Архивы',
                  subtitle: 'Публикации и кластеры',
                  icon: AppIcons.archive.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsArchiveRoute()),
                ),
                AppTile(
                  title: 'Сохраненные посты',
                  subtitle: 'Посты, которые вы сохранили',
                  icon: AppIcons.bookmarkOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SavedPostsRoute()),
                ),
              ],
            ),
            const SettingsTileSectionTitle('Аккаунт'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'Аккаунт',
                  subtitle: 'Язык, тема и выход',
                  icon: AppIcons.personOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsAccountRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsTileSectionTitle('О приложении'),
            AppTileGroup(
              children: [
                AppTile(
                  title: 'О приложении',
                  subtitle: 'Версия и онбординг',
                  icon: AppIcons.infoOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const AboutRoute()),
                ),
              ],
            ),
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}
