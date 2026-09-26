import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_catalog_/shared/catalog_l10n.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:clover/feature/_safety_/content_report/data/models/content_report_reason.dart';
import 'package:clover/feature/_safety_/content_report/data/repository/content_report_repository.dart';
import 'package:clover/feature/_safety_/content_report/data/ugc_block_session.dart';
import 'package:flutter/material.dart';

/// Жалоба / блок — общие шторки для поста и guest-профиля (App Store 1.2).
abstract final class UgcSafetyActions {
  static Future<bool> showReportSheet({
    required BuildContext context,
    required String targetUserId,
    String? postId,
  }) async {
    final l10n = context.l10n;
    final reason = await AppBottomSheet.show<ContentReportReason>(
      context: context,
      title: l10n.ugc_report_title,
      contentHeight: 340,
      content: ListView(
        children: [
          for (final r in ContentReportReason.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                r.label(l10n),
                style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.textColor),
              ),
              trailing: Icon(AppIcons.chevronRight.icon, color: context.colors.iconMuted, size: 18),
              onTap: () => Navigator.of(context).pop(r),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return false;

    try {
      await sl<ContentReportRepository>().reportContent(
        targetUserId: targetUserId,
        reason: reason,
        postId: postId,
      );
      if (!context.mounted) return true;
      AppSnackBar.show(
        context,
        message: context.l10n.ugc_report_sent,
        kind: AppSnackBarKind.success,
      );
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      AppSnackBar.show(context, message: context.l10n.ugc_report_failed, kind: AppSnackBarKind.error);
      return false;
    }
  }

  /// Returns `true` if the user was blocked.
  static Future<bool> confirmAndBlock({
    required BuildContext context,
    required String targetUserId,
    String? postId,
  }) async {
    final l10n = context.l10n;
    final ok = await AppDialog.showConfirm(
      context: context,
      title: l10n.ugc_block_title,
      message: l10n.ugc_block_body,
      confirmLabel: l10n.ugc_block_confirm,
      confirmIsDestructive: true,
      upperCaseTitle: false,
    );
    if (ok != true || !context.mounted) return false;

    try {
      await sl<SocialGraphRepository>().blockUser(
        targetUserId,
        reason: ContentReportReason.abusiveUser.apiKey,
        postId: postId,
      );
      sl<UgcBlockSession>().markBlocked(targetUserId);
      if (!context.mounted) return true;
      AppSnackBar.show(
        context,
        message: context.l10n.ugc_block_success,
        kind: AppSnackBarKind.success,
      );
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      AppSnackBar.show(context, message: context.l10n.ugc_block_failed, kind: AppSnackBarKind.error);
      return false;
    }
  }
}
