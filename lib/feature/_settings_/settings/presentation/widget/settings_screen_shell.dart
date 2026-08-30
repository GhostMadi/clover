import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:flutter/material.dart';

/// Общая оболочка экранов настроек: заголовок + левитирующая панель «Назад».
class SettingsScreenShell extends StatelessWidget {
  const SettingsScreenShell({
    super.key,
    required this.title,
    required this.body,
    this.extraButtons = const [],
  });

  final String title;
  final Widget body;
  final List<FunctionalButtonItem> extraButtons;

  /// Нижний зазор для [ListView]/[SingleChildScrollView] — контент не перекрывается панелью.
  static double scrollBottomGap(BuildContext context) => AppFunctionalScreen.scrollBottomClearance(context);

  @override
  Widget build(BuildContext context) {
    return AppFunctionalScreen(
      collapsed: true,
      collapsedBarWidthPerButton: 150,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          customColor: AppColors.primary,
          onTap: () => context.router.maybePop(),
        ),
        ...extraButtons,
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsTopBar(title: title),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(17, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
