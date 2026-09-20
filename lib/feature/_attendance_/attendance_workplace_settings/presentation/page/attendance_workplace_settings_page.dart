import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_workplace_settings/presentation/widget/attendance_workplace_settings_grid.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceWorkplaceSettingsPage extends StatelessWidget {
  const AttendanceWorkplaceSettingsPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    final store = sl<AttendanceContextStore>();

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final workplace = snap?.workplaceById(workplaceId);
        if (workplace == null) {
          return AttendanceScreenShell(
            title: 'Настройки',
            body: Center(
              child: Text(
                'Компания не найдена',
                style: AppTextStyle.base(15, color: context.colors.subTextColor),
              ),
            ),
          );
        }

        return AttendanceScreenShell(
          title: 'Настройки',
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              AttendanceWorkplaceSettingsGrid(
                workplaceId: workplaceId,
                workplace: workplace,
                snapshot: snap,
              ),
            ],
          ),
        );
      },
    );
  }
}
