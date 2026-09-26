import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_points/data/repository/booking_points_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:flutter/material.dart';

/// Открыть групповой чат точки записи (хозяин + active staff).
Future<void> openBookingPointChat(
  BuildContext context, {
  required String pointId,
  String? pointName,
}) async {
  if (_opening) return;
  _opening = true;

  final name = pointName?.trim();
  final title = (name != null && name.isNotEmpty) ? context.l10n.booking_point_chat_title(name) : context.l10n.booking_hub_title;

  try {
    final convId = await sl<BookingPointsRepository>().openPointChat(pointId);
    if (!context.mounted) return;
    if (convId.isEmpty) {
      AppSnackBar.show(context, message: context.l10n.booking_chat_open_failed, kind: AppSnackBarKind.error);
      return;
    }
    context.router.push(
      ChatRoute(
        chatId: convId,
        username: title,
        isGroup: true,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    final msg = e is BookingException ? e.userMessage : context.l10n.booking_chat_open_failed;
    AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
  } finally {
    _opening = false;
  }
}

var _opening = false;
