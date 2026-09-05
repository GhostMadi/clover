import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Оболочка экранов посещаемости.
class AttendanceScreenShell extends StatelessWidget {
  const AttendanceScreenShell({
    super.key,
    required this.title,
    required this.body,
    this.showAdd = false,
    this.showSave = false,
    this.canSave = true,
    this.onAddTap,
    this.onSaveTap,
    this.onBackTap,
  });

  final String title;
  final Widget body;
  final bool showAdd;
  final bool showSave;
  final bool canSave;
  final VoidCallback? onAddTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onBackTap;

  static double scrollBottomGap(BuildContext context) =>
      AppFunctionalScreen.scrollBottomClearance(context) + 24;

  @override
  Widget build(BuildContext context) {
    final accent = attendanceServiceAccent(context.colors);

    return AppFunctionalScreen(
      collapsed: true,
      collapsedBarWidthPerButton: 130,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          borderColor: accent.icon,
          iconColor: accent.icon,
          onTap: onBackTap ?? () => context.router.maybePop(),
        ),
        if (showAdd)
          FunctionalButtonItem(
            icon: AppIcons.add.icon,
            keepWhenCollapsed: true,
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            onTap: onAddTap ?? () {},
          ),
        if (showSave)
          FunctionalButtonItem(
            icon: AppIcons.checkRounded.icon,
            label: 'Сохранить',
            keepWhenCollapsed: true,
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            textColor: accent.ctaForeground,
            onTap: canSave ? (onSaveTap ?? () {}) : () {},
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AttendanceTopBar(title: title, accent: accent),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _AttendanceTopBar extends StatelessWidget {
  const _AttendanceTopBar({required this.title, required this.accent});

  final String title;
  final AppServiceAccent accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 3, color: accent.icon),
            SizedBox(
              height: kToolbarHeight,
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(17, color: context.colors.textColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
