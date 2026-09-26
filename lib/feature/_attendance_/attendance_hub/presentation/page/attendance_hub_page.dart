import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
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
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceHubPage extends StatefulWidget {
  const AttendanceHubPage({super.key});

  @override
  State<AttendanceHubPage> createState() => _AttendanceHubPageState();
}

class _AttendanceHubPageState extends State<AttendanceHubPage> {
  late final AttendanceHubCubit _cubit;
  late final AttendanceContextStore _attendanceStore;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _attendanceStore = sl<AttendanceContextStore>();
    _cubit = sl<AttendanceHubCubit>()..load();
    final snap = _attendanceStore.snapshot.value;
    _isWorker = snap?.showProfileWorkerButton ?? false;
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openCompany(AttendanceWorkplace workplace) async {
    await _cubit.remember(workplace.id);
    if (!mounted) return;
    await context.router.push(AttendanceCompanyRoute(workplaceId: workplace.id));
  }

  Future<void> _createWorkplace({String? folderId}) async {
    final hasTag =
        sl<ProfileCubit>().state.mapOrNull(loaded: (s) => s.profile.hasAttendanceTag) ?? false;
    if (!hasTag) {
      AppSnackBar.show(
        context,
        message: context.l10n.attendance_hub_admin_tag_required,
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final nameController = TextEditingController(text: context.l10n.attendance_company_default_name);
    try {
      final name = await AttendanceBottomSheet.show<String>(
        context: context,
        title: context.l10n.attendance_hub_new_company,
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

      final ok = await _cubit.createWorkplace(name: name, folderId: folderId);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ok ? context.l10n.attendance_hub_company_created : context.l10n.attendance_hub_company_create_failed,
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

    return BlocBuilder<AttendanceHubCubit, AttendanceHubState>(
      bloc: _cubit,
      builder: (context, state) {
        final loaded = state is AttendanceHubLoaded ? state : null;
        final workplaces = loaded?.adminWorkplaces ?? const <AttendanceWorkplace>[];
        final snap = loaded?.snapshot;
        final worker = _isWorker || (snap?.showProfileWorkerButton ?? false);
        final loading =
            (state is AttendanceHubInitial || state is AttendanceHubLoading) && workplaces.isEmpty;
        final refreshing = loaded?.isRefreshing == true;

        if (loading) {
          return AttendanceScreenShell(
            title: context.l10n.attendance_hub_title,
            body: const AttendanceLoader(),
          );
        }

        if (state is AttendanceHubError && workplaces.isEmpty) {
          return AttendanceScreenShell(
            title: context.l10n.attendance_hub_title,
            body: _EmptyAdminBody(onRefresh: _cubit.load),
          );
        }

        return AttendanceScreenShell(
          title: context.l10n.attendance_hub_title,
          showAdd: true,
          onAddTap: () => _createWorkplace(),
          body: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: Stack(
              children: [
                ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    Text(
                      context.l10n.attendance_hub_companies,
                      style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    if (workplaces.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          context.l10n.attendance_hub_empty_hint,
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
                      SizedBox(height: 20),
                      Text(
                        context.l10n.attendance_analytics_shifts,
                        style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      AppTileGroup(
                        children: [
                          AppTile(
                            title: context.l10n.attendance_hub_my_attendance,
                            subtitle: context.l10n.attendance_hub_my_attendance_subtitle,
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
          ),
        );
      },
    );
  }
}

class _EmptyAdminBody extends StatelessWidget {
  const _EmptyAdminBody({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.attendance_hub_empty_admin,
            style: AppTextStyle.base(15, color: colors.subTextColor),
          ),
          SizedBox(height: 20),
          AppOutlinedButton(
            text: context.l10n.common_refresh,
            isExpanded: true,
            service: kAttendanceService,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}
