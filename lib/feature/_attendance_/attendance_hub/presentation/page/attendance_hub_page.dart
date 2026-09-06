import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/attendance_hub/presentation/cubit/attendance_hub_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class AttendanceHubPage extends StatefulWidget {
  const AttendanceHubPage({super.key});

  @override
  State<AttendanceHubPage> createState() => _AttendanceHubPageState();
}

class _AttendanceHubPageState extends State<AttendanceHubPage> {
  late final AttendanceHubCubit _cubit;
  late final ProfileAttendanceAdminShortcutStore _shortcutStore;
  bool _shortcutLoading = true;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceHubCubit>()..load();
    _shortcutStore = sl<ProfileAttendanceAdminShortcutStore>();
    _loadShortcut();
  }

  Future<void> _loadShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _shortcutLoading = false);
      return;
    }
    await _shortcutStore.load(uid);
    if (mounted) setState(() => _shortcutLoading = false);
  }

  Future<void> _setShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _shortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _createWorkplace({String? folderId}) async {
    final nameController = TextEditingController(text: 'Компания');
    try {
      final name = await AttendanceBottomSheet.show<String>(
        context: context,
        title: 'Новая компания',
        content: AttendanceField(
          controller: nameController,
          labelText: 'Название',
          textInputAction: TextInputAction.done,
        ),
        actions: [
          AttendancePrimaryButton(
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

      final ok = await _cubit.createWorkplace(name: name, folderId: folderId);
      if (!mounted) return;
      if (ok) {
        AppSnackBar.show(context, message: 'Компания создана', kind: AppSnackBarKind.success);
      } else {
        AppSnackBar.show(context, message: 'Не удалось создать компанию', kind: AppSnackBarKind.error);
      }
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), nameController.dispose);
    }
  }

  Future<void> _createFolder() async {
    final nameController = TextEditingController();
    try {
      final name = await AttendanceBottomSheet.show<String>(
        context: context,
        title: 'Новая папка',
        content: AttendanceField(
          controller: nameController,
          labelText: 'Название папки',
          textInputAction: TextInputAction.done,
        ),
        actions: [
          AttendancePrimaryButton(
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
      final ok = await _cubit.createFolder(name);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ok ? 'Папка создана' : 'Не удалось создать папку',
        kind: ok ? AppSnackBarKind.success : AppSnackBarKind.error,
      );
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), nameController.dispose);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<AttendanceHubCubit, AttendanceHubState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is AttendanceHubInitial || state is AttendanceHubLoading) {
          return AttendanceScreenShell(
            title: 'Посещаемость',
            body: Center(child: CircularProgressIndicator(color: colors.serviceAccent(kAttendanceService).icon)),
          );
        }

        if (state is AttendanceHubError) {
          return AttendanceScreenShell(
            title: 'Посещаемость',
            body: _EmptyAdminBody(
              onRefresh: _cubit.load,
              shortcutLoading: _shortcutLoading,
              shortcutValue: _shortcutStore.visible.value,
              onShortcutChanged: _setShortcut,
            ),
          );
        }

        final loaded = state as AttendanceHubLoaded;
        final workplaces = loaded.adminWorkplaces;

        return AttendanceScreenShell(
          title: 'Посещаемость',
          showAdd: true,
          onAddTap: () => _createWorkplace(),
          body: workplaces.isEmpty && loaded.snapshot.folders.isEmpty
              ? _EmptyAdminBody(
                  onRefresh: _cubit.load,
                  shortcutLoading: _shortcutLoading,
                  shortcutValue: _shortcutStore.visible.value,
                  onShortcutChanged: _setShortcut,
                )
              : _AdminHubBody(
                  snapshot: loaded.snapshot,
                  shortcutLoading: _shortcutLoading,
                  shortcutValue: _shortcutStore.visible.value,
                  onShortcutChanged: _setShortcut,
                  onCreateFolder: _createFolder,
                  onCreateInFolder: (folderId) => _createWorkplace(folderId: folderId),
                  onMove: (workplaceId, folderId) async {
                    final ok = await _cubit.moveWorkplaceToFolder(
                      workplaceId: workplaceId,
                      folderId: folderId,
                    );
                    if (!mounted) return;
                    if (!ok) {
                      AppSnackBar.show(this.context, message: 'Не удалось переместить', kind: AppSnackBarKind.error);
                    }
                  },
                ),
        );
      },
    );
  }
}

class _EmptyAdminBody extends StatelessWidget {
  const _EmptyAdminBody({
    required this.onRefresh,
    required this.shortcutLoading,
    required this.shortcutValue,
    required this.onShortcutChanged,
  });

  final VoidCallback onRefresh;
  final bool shortcutLoading;
  final bool shortcutValue;
  final ValueChanged<bool> onShortcutChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTileGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppSwitchRow(
                  title: 'Кнопка в профиле',
                  subtitle: 'Быстрый переход к компаниям',
                  value: shortcutValue,
                  enabled: !shortcutLoading,
                  onChanged: shortcutLoading ? null : onShortcutChanged,
                  service: kAttendanceService,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Создайте компанию: геозона, работники и отметки.',
            style: AppTextStyle.base(15, color: colors.subTextColor),
          ),
          const SizedBox(height: 20),
          AppOutlinedButton(
            text: 'Обновить',
            isExpanded: true,
            service: kAttendanceService,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _AdminHubBody extends StatelessWidget {
  const _AdminHubBody({
    required this.snapshot,
    required this.shortcutLoading,
    required this.shortcutValue,
    required this.onShortcutChanged,
    required this.onCreateFolder,
    required this.onCreateInFolder,
    required this.onMove,
  });

  final AttendanceSnapshot snapshot;
  final bool shortcutLoading;
  final bool shortcutValue;
  final ValueChanged<bool> onShortcutChanged;
  final VoidCallback onCreateFolder;
  final ValueChanged<String> onCreateInFolder;
  final Future<void> Function(String workplaceId, String? folderId) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final workplaces = snapshot.workplaces.where((e) => e.isAdmin).toList(growable: false);
    final folders = snapshot.folders;
    final unfiled = workplaces.where((w) => w.folderId == null || w.folderId!.isEmpty).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTileGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppSwitchRow(
                  title: 'Кнопка в профиле',
                  subtitle: 'Быстрый переход к компаниям',
                  value: shortcutValue,
                  enabled: !shortcutLoading,
                  onChanged: shortcutLoading ? null : onShortcutChanged,
                  service: kAttendanceService,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Компании', style: AppTextStyle.base(13, color: colors.subTextColor)),
              ),
              TextButton(
                onPressed: onCreateFolder,
                child: Text(
                  'Папка',
                  style: AppTextStyle.base(13, color: colors.serviceAccent(kAttendanceService).icon, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final folder in folders) ...[
            Text(folder.name, style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            AppTileGroup(
              children: [
                for (final workplace in workplaces.where((w) => w.folderId == folder.id))
                  _WorkplaceTile(
                    workplace: workplace,
                    folders: folders,
                    onMove: onMove,
                  ),
                AttendanceServiceTile(
                  title: 'Добавить компанию в папку',
                  icon: AppIcons.add.icon,
                  showChevron: false,
                  onTap: () => onCreateInFolder(folder.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (unfiled.isNotEmpty || folders.isEmpty) ...[
            if (folders.isNotEmpty)
              Text('Без папки', style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700)),
            if (folders.isNotEmpty) const SizedBox(height: 6),
            AppTileGroup(
              children: [
                for (final workplace in unfiled)
                  _WorkplaceTile(
                    workplace: workplace,
                    folders: folders,
                    onMove: onMove,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkplaceTile extends StatelessWidget {
  const _WorkplaceTile({
    required this.workplace,
    required this.folders,
    required this.onMove,
  });

  final AttendanceWorkplace workplace;
  final List<AttendanceFolder> folders;
  final Future<void> Function(String workplaceId, String? folderId) onMove;

  Future<void> _pickFolder(BuildContext context) async {
    if (folders.isEmpty) return;
    final choice = await AttendanceBottomSheet.show<String?>(
      context: context,
      title: 'Папка',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTile(
            title: 'Без папки',
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final f in folders)
            AppTile(
              title: f.name,
              onTap: () => Navigator.of(context).pop(f.id),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await onMove(workplace.id, choice.isEmpty ? null : choice);
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceServiceTile(
      title: workplace.name,
      icon: AppIcons.inventory.icon,
      showChevron: true,
      trailing: folders.isEmpty
          ? null
          : IconButton(
              icon: Icon(AppIcons.folder.icon, size: 20, color: context.colors.iconMuted),
              onPressed: () => _pickFolder(context),
            ),
      onTap: () => context.router.push(AttendanceCompanyRoute(workplaceId: workplace.id)),
    );
  }
}
