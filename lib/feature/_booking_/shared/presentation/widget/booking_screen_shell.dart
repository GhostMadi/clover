import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
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
    this.showCancel = false,
    this.canSave = false,
    this.saveLabel = 'Сохранить',
    this.cancelLabel = 'Отменить',
    this.cancelIcon,
    this.onAnalyticsTap,
    this.onCreateTap,
    this.onAddTap,
    this.onServicesTap,
    this.onFilterTap,
    this.onSettingsTap,
    this.onSaveTap,
    this.onCancelTap,
    this.onBackTap,
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
  final bool showCancel;
  final bool canSave;
  final String saveLabel;
  final String cancelLabel;
  final IconData? cancelIcon;
  final VoidCallback? onAnalyticsTap;
  final VoidCallback? onCreateTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onServicesTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onBackTap;

  static double scrollBottomGap(BuildContext context) =>
      AppFunctionalScreen.scrollBottomClearance(context) + 24;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return AppFunctionalScreen(
      collapsed: compactBar,
      collapsedBarWidthPerButton: 130,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          borderColor: accent.icon,
          iconColor: accent.icon,
          isLoading: isLoading,
          onTap: onBackTap ?? () => context.router.maybePop(),
        ),
        if (showCancel)
          FunctionalButtonItem(
            icon: cancelIcon ?? AppIcons.block.icon,
            label: cancelLabel.isEmpty ? null : cancelLabel,
            keepWhenCollapsed: true,
            customColor: context.colors.functionalSoftRed,
            iconColor: context.colors.functionalSoftRedIcon,
            textColor: context.colors.destructive,
            isLoading: isLoading,
            onTap: onCancelTap ?? () {},
          ),
        if (showFilter)
          FunctionalButtonItem(
            icon: AppIcons.filterList.icon,
            keepWhenCollapsed: true,
            customColor: accent.soft,
            iconColor: accent.icon,
            isLoading: isLoading,
            onTap: onFilterTap ?? () {},
          ),
        if (showSettings)
          FunctionalButtonItem(
            icon: AppIcons.settingsOutlined.icon,
            keepWhenCollapsed: true,
            customColor: accent.soft,
            iconColor: accent.icon,
            isLoading: isLoading,
            onTap: onSettingsTap ?? () {},
          ),
        if (showAdd)
          FunctionalButtonItem(
            icon: AppIcons.add.icon,
            keepWhenCollapsed: true,
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            isLoading: isLoading,
            onTap: onAddTap ?? () {},
          ),
        if (showSave && (canSave || isLoading))
          FunctionalButtonItem(
            icon: AppIcons.checkRounded.icon,
            label: saveLabel,
            keepWhenCollapsed: true,
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            textColor: accent.ctaForeground,
            isLoading: isLoading,
            onTap: onSaveTap ?? () {},
          ),
        if (showServices)
          FunctionalButtonItem(
            icon: AppIcons.designServices.icon,
            label: 'Услуги',
            isLoading: isLoading,
            onTap: onServicesTap ?? () {},
          ),
        if (showAnalytics)
          FunctionalButtonItem(
            icon: AppIcons.insights.icon,
            label: 'Аналитика',
            isLoading: isLoading,
            onTap: onAnalyticsTap ?? () {},
          ),
        if (showCreate)
          FunctionalButtonItem(
            icon: AppIcons.add.icon,
            label: 'Создать',
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            textColor: accent.ctaForeground,
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
      color: context.colors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
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
      ),
    );
  }
}
