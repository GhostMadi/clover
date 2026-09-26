import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
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
    final l10n = context.l10n;
    final booking = bookingServiceAccent(context.colors);
    final attendance = attendanceServiceAccent(context.colors);
    final resources = context.colors.serviceAccent(kResourcesService);

    return SettingsScreenShell(
      title: l10n.settings_title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<ProfileCubit, ProfileState>(
              bloc: sl<ProfileCubit>(),
              builder: (context, state) {
                final hasBooking = state.mapOrNull(loaded: (s) => s.profile.hasBookingTag) ?? false;
                final hasAttendance =
                    state.mapOrNull(loaded: (s) => s.profile.hasAttendanceTag) ?? false;
                final hasResources =
                    state.mapOrNull(loaded: (s) => s.profile.hasResourcesTag) ?? false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsTileSectionTitle(l10n.settings_section_services),
                    AppTileGroup(
                      children: [
                        AppTile(
                          title: l10n.settings_guide_title,
                          subtitle: l10n.settings_guide_subtitle,
                          icon: AppIcons.infoOutline.icon,
                          iconColor: context.colors.primary,
                          iconBackgroundColor: context.colors.successSoft,
                          showChevron: true,
                          onTap: () => context.router.push(const SettingsGuideRoute()),
                        ),
                        if (hasBooking)
                          AppTile(
                            title: l10n.settings_booking_title,
                            subtitle: l10n.settings_booking_subtitle,
                            icon: AppIcons.calendarMonth.icon,
                            iconColor: booking.icon,
                            iconBackgroundColor: booking.soft,
                            showChevron: true,
                            onTap: () => context.router.push(const SettingsBookingRoute()),
                          ),
                        if (hasAttendance)
                          AppTile(
                            title: l10n.settings_attendance_title,
                            subtitle: l10n.settings_attendance_subtitle,
                            icon: AppIcons.schedule.icon,
                            iconColor: attendance.icon,
                            iconBackgroundColor: attendance.soft,
                            showChevron: true,
                            onTap: () => context.router.push(const SettingsAttendanceRoute()),
                          ),
                        if (hasResources)
                          AppTile(
                            title: l10n.settings_resources_title,
                            subtitle: l10n.settings_resources_subtitle,
                            icon: AppIcons.inventory.icon,
                            iconColor: resources.icon,
                            iconBackgroundColor: resources.soft,
                            showChevron: true,
                            onTap: () => context.router.push(const SettingsResourcesRoute()),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            SettingsTileSectionTitle(l10n.settings_section_archives),
            AppTileGroup(
              children: [
                AppTile(
                  title: l10n.settings_archives_title,
                  subtitle: l10n.settings_archives_subtitle,
                  icon: AppIcons.archive.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsArchiveRoute()),
                ),
                AppTile(
                  title: l10n.settings_saved_posts_title,
                  subtitle: l10n.settings_saved_posts_subtitle,
                  icon: AppIcons.bookmarkOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SavedPostsRoute()),
                ),
              ],
            ),
            SettingsTileSectionTitle(l10n.settings_section_account),
            AppTileGroup(
              children: [
                AppTile(
                  title: l10n.settings_account_title,
                  subtitle: l10n.settings_account_subtitle,
                  icon: AppIcons.personOutline.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsAccountRoute()),
                ),
                AppTile(
                  title: l10n.settings_blocked_title,
                  subtitle: l10n.settings_blocked_subtitle,
                  icon: AppIcons.block.icon,
                  showChevron: true,
                  onTap: () => context.router.push(const SettingsBlockedRoute()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SettingsTileSectionTitle(l10n.settings_section_about),
            AppTileGroup(
              children: [
                AppTile(
                  title: l10n.settings_about_title,
                  subtitle: l10n.settings_about_subtitle,
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
