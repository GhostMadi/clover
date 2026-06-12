import 'dart:ui' as ui;

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Центрированный диалог в стиле [AppBottomSheet]: блюр, скругление 32, та же палитра и обводка.
abstract final class AppDialog {
  /// Подтверждение (две кнопки). `true` — подтверждение, `false` — отмена, `null` — закрытие по барьеру.
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    String cancelLabel = 'Отмена',
    required String confirmLabel,
    bool confirmIsDestructive = false,
    bool barrierDismissible = true,
    bool upperCaseTitle = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppColors.bottomBarColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.bottomBarActiveIcon.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  upperCaseTitle ? title.toUpperCase() : title,
                                  style: AppTextStyle.base(
                                    17,
                                    color: AppColors.textColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    letterSpacing: upperCaseTitle ? 0.35 : 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (message != null && message.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Text(
                              message,
                              style: AppTextStyle.base(15, color: AppColors.subTextColor, height: 1.45),
                            ),
                          ),
                        ],
                        Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.65)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(ctx).pop(false);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textColor,
                                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.85)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  child: Text(
                                    cancelLabel,
                                    style: AppTextStyle.base(16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(ctx).pop(true);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: confirmIsDestructive
                                        ? AppColors.error
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  child: Text(
                                    confirmLabel,
                                    style: AppTextStyle.base(
                                      16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
