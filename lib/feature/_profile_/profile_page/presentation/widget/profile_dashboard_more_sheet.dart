import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:flutter/material.dart';

abstract final class ProfileDashboardMoreSheet {
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTile(
            icon: AppIcons.calendarMonth.icon,
            title: 'Мои бронирования',
            onTap: () {
              Navigator.of(context).pop();
              context.router.push(const MyBookingsRoute());
            },
          ),
          AppTile(
            icon: AppIcons.loyalty.icon,
            title: 'Мои бонусы',
            onTap: () {
              Navigator.of(context).pop();
              context.router.push(const MyBonusesRoute());
            },
          ),
        ],
      ),
    );
  }
}
