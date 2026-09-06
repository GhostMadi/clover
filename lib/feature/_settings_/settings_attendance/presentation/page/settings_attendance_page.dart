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
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Настройки «Посещаемость»: тогл ярлыка + сразу список компаний (без промежуточного «Управление»).
@RoutePage()
class SettingsAttendancePage extends StatefulWidget {
  const SettingsAttendancePage({super.key});

  @override
  State<SettingsAttendancePage> createState() => _SettingsAttendancePageState();
}

class _SettingsAttendancePageState extends State<SettingsAttendancePage> {
  late final ProfileAttendanceAdminShortcutStore _adminShortcutStore;
  late final AttendanceContextStore _attendanceStore;
  late final AttendanceHubCubit _hubCubit;
  bool _shortcutLoading = true;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _adminShortcutStore = sl<ProfileAttendanceAdminShortcutStore>();
    _attendanceStore = sl<AttendanceContextStore>();
    _hubCubit = sl<AttendanceHubCubit>()..load();
    _loadShortcut();
  }

  @override
  void dispose() {
    _hubCubit.close();
    super.dispose();
  }

  Future<void> _loadShortcut() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _shortcutLoading = false);
      return;
    }
    await _adminShortcutStore.load(uid);
    final snap = _attendanceStore.snapshot.value;
    if (mounted) {
      setState(() {
        _isWorker = snap?.showProfileWorkerButton ?? false;
        _shortcutLoading = false;
      });
    }
  }

  Future<void> _setAdminShortcut(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;
    await _adminShortcutStore.setVisible(uid, value);
    if (mounted) setState(() {});
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

      final ok = await _hubCubit.createWorkplace(name: name, folderId: folderId);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ok ? 'Компания создана' : 'Не удалось создать компанию',
        kind: ok ? AppSnackBarKind.success : AppSnackBarKind.error,
      );
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
      final ok = await _hubCubit.createFolder(name);
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
    final accent = attendanceServiceAccent(colors);

    return SettingsScreenShell(
      title: 'Посещаемость',
      service: kAttendanceService,
      body: BlocBuilder<AttendanceHubCubit, AttendanceHubState>(
        bloc: _hubCubit,
        builder: (context, state) {
          final loaded = state is AttendanceHubLoaded ? state : null;
          final snap = loaded?.snapshot;
          final isAdmin = snap?.isAdmin ?? false;
          final worker = _isWorker || (snap?.showProfileWorkerButton ?? false);
          final loading = state is AttendanceHubInitial || state is AttendanceHubLoading;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SettingsTileSectionTitle('Профиль'),
                AppTileGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AppSwitchRow(
                        title: 'Кнопка в профиле',
                        subtitle: 'Быстрый переход к компаниям',
                        value: _adminShortcutStore.visible.value,
                        enabled: !_shortcutLoading,
                        onChanged: _shortcutLoading ? null : _setAdminShortcut,
                        service: kAttendanceService,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Компании',
                        style: AppTextStyle.base(13, color: colors.subTextColor),
                      ),
                    ),
                    if (!loading)
                      TextButton(
                        onPressed: _createFolder,
                        child: Text(
                          'Папка',
                          style: AppTextStyle.base(
                            13,
                            color: accent.icon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: loading ? null : () => _createWorkplace(),
                      child: Text(
                        'Добавить',
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
                if (loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: accent.icon, strokeWidth: 2.4),
                    ),
                  )
                else if (state is AttendanceHubError)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Не удалось загрузить компании',
                        style: AppTextStyle.base(14, color: colors.subTextColor),
                      ),
                      const SizedBox(height: 12),
                      AppOutlinedButton(
                        text: 'Обновить',
                        isExpanded: true,
                        service: kAttendanceService,
                        onTap: _hubCubit.load,
                      ),
                    ],
                  )
                else if (snap == null ||
                    (snap.workplaces.where((w) => w.isAdmin).isEmpty && snap.folders.isEmpty))
                  AppTileGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                        child: Text(
                          isAdmin || snap != null
                              ? 'Пока нет компаний. Нажмите «Добавить».'
                              : 'Создайте компанию: геозона, работники и отметки.',
                          style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
                        ),
                      ),
                    ],
                  )
                else
                  _CompaniesList(
                    snapshot: snap,
                    onCreateInFolder: (folderId) => _createWorkplace(folderId: folderId),
                    onMove: (workplaceId, folderId) async {
                      final ok = await _hubCubit.moveWorkplaceToFolder(
                        workplaceId: workplaceId,
                        folderId: folderId,
                      );
                      if (!mounted) return;
                      if (!ok) {
                        AppSnackBar.show(
                          this.context,
                          message: 'Не удалось переместить',
                          kind: AppSnackBarKind.error,
                        );
                      }
                    },
                  ),
                if (worker) ...[
                  const SizedBox(height: 20),
                  const SettingsTileSectionTitle('Смены'),
                  AppTileGroup(
                    children: [
                      AppTile(
                        title: 'Моя посещаемость',
                        subtitle: 'Отметки и смены',
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
          );
        },
      ),
    );
  }
}

class _CompaniesList extends StatelessWidget {
  const _CompaniesList({
    required this.snapshot,
    required this.onCreateInFolder,
    required this.onMove,
  });

  final AttendanceSnapshot snapshot;
  final ValueChanged<String> onCreateInFolder;
  final Future<void> Function(String workplaceId, String? folderId) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final workplaces = snapshot.workplaces.where((e) => e.isAdmin).toList(growable: false);
    final folders = snapshot.folders;
    final unfiled = workplaces.where((w) => w.folderId == null || w.folderId!.isEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final folder in folders) ...[
          Text(folder.name, style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AppTileGroup(
            children: [
              for (final workplace in workplaces.where((w) => w.folderId == folder.id))
                _WorkplaceTile(workplace: workplace, folders: folders, onMove: onMove),
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
                _WorkplaceTile(workplace: workplace, folders: folders, onMove: onMove),
            ],
          ),
        ],
      ],
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
