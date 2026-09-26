import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/attendance_hub/presentation/cubit/attendance_hub_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_hub_nav_card.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clover/core/extension/context.dart';

/// Настройки «Посещаемость»: список компаний гридом (как Запись → точки).
@RoutePage()
class SettingsAttendancePage extends StatefulWidget {
  const SettingsAttendancePage({super.key});

  @override
  State<SettingsAttendancePage> createState() => _SettingsAttendancePageState();
}

class _SettingsAttendancePageState extends State<SettingsAttendancePage> {
  late final AttendanceContextStore _attendanceStore;
  late final AttendanceHubCubit _hubCubit;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _attendanceStore = sl<AttendanceContextStore>();
    _hubCubit = sl<AttendanceHubCubit>()..load();
    final snap = _attendanceStore.snapshot.value;
    _isWorker = snap?.showProfileWorkerButton ?? false;
  }

  @override
  void dispose() {
    _hubCubit.close();
    super.dispose();
  }

  Future<void> _openCompany(AttendanceWorkplace workplace) async {
    await _hubCubit.remember(workplace.id);
    if (!mounted) return;
    await context.router.push(AttendanceCompanyRoute(workplaceId: workplace.id));
  }

  Future<void> _createWorkplace({String? folderId}) async {
    final hasTag =
        sl<ProfileCubit>().state.mapOrNull(loaded: (s) => s.profile.hasAttendanceTag) ?? false;
    if (!hasTag) {
      AppSnackBar.show(
        context,
        message: context.l10n.settings_attendance_enable_tag,
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final nameController = TextEditingController(text: context.l10n.settings_attendance_company);
    try {
      final name = await AttendanceBottomSheet.show<String>(
        context: context,
        title: context.l10n.settings_attendance_new_company,
        content: AttendanceField(
          controller: nameController,
          labelText: context.l10n.common_name,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          Builder(
            builder: (sheetContext) => AttendancePrimaryButton(
              text: context.l10n.common_create,
              isExpanded: true,
              onTap: () {
                final value = nameController.text.trim();
                if (value.isEmpty) return;
                Navigator.of(sheetContext).pop(value);
              },
            ),
          ),
        ],
      );

      if (name == null || name.isEmpty || !mounted) return;

      final ok = await _hubCubit.createWorkplace(name: name, folderId: folderId);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ok
            ? context.l10n.settings_attendance_company_created
            : context.l10n.settings_attendance_company_create_failed,
        kind: ok ? AppSnackBarKind.success : AppSnackBarKind.error,
      );
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), nameController.dispose);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return SettingsScreenShell(
      title: context.l10n.settings_attendance_title,
      service: kAttendanceService,
      body: BlocBuilder<AttendanceHubCubit, AttendanceHubState>(
        bloc: _hubCubit,
        builder: (context, state) {
          final loaded = state is AttendanceHubLoaded ? state : null;
          final workplaces = loaded?.adminWorkplaces ?? const <AttendanceWorkplace>[];
          final snap = loaded?.snapshot;
          final worker = _isWorker || (snap?.showProfileWorkerButton ?? false);
          final loading = (state is AttendanceHubInitial || state is AttendanceHubLoading) &&
              workplaces.isEmpty;
          final refreshing = loaded?.isRefreshing == true;

          if (loading) {
            return const AttendanceLoader();
          }

          if (state is AttendanceHubError && workplaces.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.settings_companies_load_failed,
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                  const SizedBox(height: 12),
                  AppOutlinedButton(
                    text: context.l10n.common_refresh,
                    isExpanded: true,
                    service: kAttendanceService,
                    onTap: _hubCubit.load,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _hubCubit.refresh,
            child: Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.settings_attendance_companies,
                            style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _createWorkplace(),
                          child: Text(
                            context.l10n.common_add,
                            style: AppTextStyle.base(
                              13,
                              color: accent.icon,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (workplaces.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          context.l10n.settings_companies_empty,
                          style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
                        ),
                      )
                    else
                      AttendanceHubNavGrid(
                        children: [
                          for (final workplace in workplaces)
                            AttendanceHubNavCard(
                              title: workplace.name,
                              subtitle: context.l10n.common_open,
                              icon: AppIcons.inventory.icon,
                              onTap: () => _openCompany(workplace),
                            ),
                        ],
                      ),
                    if (worker) ...[
                      const SizedBox(height: 20),
                      SettingsTileSectionTitle(context.l10n.settings_attendance_shifts),
                      AppTileGroup(
                        children: [
                          AppTile(
                            title: context.l10n.settings_attendance_my_title,
                            subtitle: context.l10n.settings_attendance_my_subtitle,
                            icon: AppIcons.accessTime.icon,
                            iconColor: accent.icon,
                            iconBackgroundColor: accent.soft,
                            showChevron: true,
                            onTap: () => context.router.push(const AttendanceWorkerHubRoute()),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (refreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: accent.icon,
                      backgroundColor: accent.soft,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
