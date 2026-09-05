import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceHubPage extends StatefulWidget {
  const AttendanceHubPage({super.key});

  @override
  State<AttendanceHubPage> createState() => _AttendanceHubPageState();
}

class _AttendanceHubPageState extends State<AttendanceHubPage> {
  late final AttendanceContextStore _store;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _store = sl<AttendanceContextStore>();
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() => _loading = true);
    await _store.hydrateCurrent();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _createWorkplace() async {
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

      try {
        await _store.createWorkplace(name: name);
        if (!mounted) return;
        setState(() {});
        AppSnackBar.show(context, message: 'Компания создана', kind: AppSnackBarKind.success);
      } catch (_) {
        if (!mounted) return;
        AppSnackBar.show(context, message: 'Не удалось создать компанию', kind: AppSnackBarKind.error);
      }
    } finally {
      // Sheet ещё анимируется — dispose только после закрытия route.
      Future<void>.delayed(const Duration(milliseconds: 400), nameController.dispose);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return AttendanceScreenShell(
        title: 'Посещаемость',
        body: Center(child: CircularProgressIndicator(color: colors.serviceAccent(kAttendanceService).icon)),
      );
    }

    return ValueListenableBuilder(
      valueListenable: _store.snapshot,
      builder: (context, snap, _) {
        final workplaces = snap?.workplaces.where((w) => w.isAdmin).toList(growable: false) ?? const [];

        return AttendanceScreenShell(
          title: 'Посещаемость',
          showAdd: true,
          onAddTap: _createWorkplace,
          body: workplaces.isEmpty
              ? _EmptyAdminBody(onRefresh: _hydrate)
              : _AdminHubBody(snapshot: snap!),
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
  const _AdminHubBody({required this.snapshot});

  final AttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final workplaces = snapshot.workplaces.where((e) => e.isAdmin).toList(growable: false);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Компании', style: AppTextStyle.base(13, color: colors.subTextColor)),
          const SizedBox(height: 8),
          AppTileGroup(
            children: [
              for (final workplace in workplaces)
                AttendanceServiceTile(
                  title: workplace.name,
                  icon: AppIcons.inventory.icon,
                  showChevron: true,
                  onTap: () => context.router.push(AttendanceCompanyRoute(workplaceId: workplace.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
