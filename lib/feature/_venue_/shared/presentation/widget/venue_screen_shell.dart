import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

/// Оболочка экранов брони: заголовок + левитирующая «Назад».
class VenueScreenShell extends StatelessWidget {
  const VenueScreenShell({
    super.key,
    required this.title,
    required this.body,
    this.extraButtons = const [],
  });

  final String title;
  final Widget body;
  final List<FunctionalButtonItem> extraButtons;

  static double scrollBottomGap(BuildContext context) =>
      AppFunctionalScreen.scrollBottomClearance(context) + 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = venueServiceAccent(colors);

    return AppFunctionalScreen(
      collapsed: true,
      collapsedBarWidthPerButton: 130,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          iconColor: accent.ctaForeground,
          customColor: accent.cta,
          keepWhenCollapsed: true,
          onTap: () => context.router.maybePop(),
        ),
        ...extraButtons,
      ],
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                title,
                style: AppTextStyle.base(22, fontWeight: FontWeight.w700, color: colors.textColor),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
