import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:flutter/material.dart';

/// Оболочка экранов записи: заголовок + левитирующая нижняя панель [AppFunctionalScreen].
class BookingScreenShell extends StatelessWidget {
  const BookingScreenShell({
    super.key,
    required this.title,
    required this.body,
    this.compactBar = false,
    this.isLoading = false,
    this.showAnalytics = false,
    this.showCreate = false,
    this.showAdd = false,
    this.showServices = false,
    this.showFilter = false,
    this.showSettings = false,
    this.showSave = false,
    this.canSave = false,
    this.saveLabel = 'Сохранить',
    this.onAnalyticsTap,
    this.onCreateTap,
    this.onAddTap,
    this.onServicesTap,
    this.onFilterTap,
    this.onSettingsTap,
    this.onSaveTap,
  });

  final String title;
  final Widget body;
  final bool compactBar;
  final bool isLoading;
  final bool showAnalytics;
  final bool showCreate;
  final bool showAdd;
  final bool showServices;
  final bool showFilter;
  final bool showSettings;
  final bool showSave;
  final bool canSave;
  final String saveLabel;
  final VoidCallback? onAnalyticsTap;
  final VoidCallback? onCreateTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onServicesTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSaveTap;

  static double scrollBottomGap(BuildContext context) => AppFunctionalScreen.scrollBottomClearance(context);

  @override
  Widget build(BuildContext context) {
    return AppFunctionalScreen(
      collapsed: compactBar,
      collapsedBarWidthPerButton: 130,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          customColor: AppColors.primary,
          isLoading: isLoading,
          onTap: () => context.router.maybePop(),
        ),
        if (showFilter)
          FunctionalButtonItem(
            icon: Icons.filter_list_rounded,
            keepWhenCollapsed: true,
            customColor: AppColors.functionalSoftBlue,
            iconColor: AppColors.functionalSoftBlueIcon,
            isLoading: isLoading,
            onTap: onFilterTap ?? () {},
          ),
        if (showSettings)
          FunctionalButtonItem(
            icon: Icons.settings_outlined,
            keepWhenCollapsed: true,
            customColor: AppColors.functionalSoftBlue,
            iconColor: AppColors.functionalSoftBlueIcon,
            isLoading: isLoading,
            onTap: onSettingsTap ?? () {},
          ),
        if (showAdd)
          FunctionalButtonItem(
            icon: AppIcons.add.icon,
            keepWhenCollapsed: true,
            customColor: AppColors.primary,
            iconColor: Colors.white,
            isLoading: isLoading,
            onTap: onAddTap ?? () {},
          ),
        if (showSave && (canSave || isLoading))
          FunctionalButtonItem(
            icon: Icons.check_rounded,
            label: saveLabel,
            keepWhenCollapsed: true,
            customColor: AppColors.primary,
            iconColor: Colors.white,
            textColor: Colors.white,
            isLoading: isLoading,
            onTap: onSaveTap ?? () {},
          ),
        if (showServices)
          FunctionalButtonItem(
            icon: Icons.design_services_outlined,
            label: 'Услуги',
            isLoading: isLoading,
            onTap: onServicesTap ?? () {},
          ),
        if (showAnalytics)
          FunctionalButtonItem(
            icon: Icons.insights_outlined,
            label: 'Аналитика',
            isLoading: isLoading,
            onTap: onAnalyticsTap ?? () {},
          ),
        if (showCreate)
          FunctionalButtonItem(
            icon: AppIcons.add.icon,
            label: 'Создать',
            customColor: AppColors.primary,
            iconColor: Colors.white,
            textColor: Colors.white,
            isLoading: isLoading,
            onTap: onCreateTap ?? () {},
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BookingTopBar(title: title),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _BookingTopBar extends StatelessWidget {
  const _BookingTopBar({required this.title});

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
