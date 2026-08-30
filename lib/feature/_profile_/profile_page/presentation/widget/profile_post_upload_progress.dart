import 'dart:io';

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

enum ProfilePostUploadStatus { uploading, success, failure }

/// Карточка прогресса / статуса публикации поста в профиле.
class ProfilePostUploadProgress extends StatelessWidget {
  const ProfilePostUploadProgress({
    super.key,
    required this.title,
    required this.status,
    this.progress = 0,
    this.statusMessage,
    this.localImagePath,
    this.imageUrl,
    this.successLabel = 'Успешно опубликовано',
    this.failureLabel = 'Не удалось опубликовать',
  });

  final String title;
  final ProfilePostUploadStatus status;
  final int progress;
  final String? statusMessage;
  final String? localImagePath;
  final String? imageUrl;
  final String successLabel;
  final String failureLabel;

  static const double _figmaPaddingH = 16;
  static const double _figmaPaddingV = 12;
  static const double _figmaCardRadius = 14;
  static const double _figmaThumbSize = 52;
  static const double _figmaThumbRadius = 10;
  static const double _figmaRowGap = 12;
  static const double _figmaProgressGap = 10;
  static const double _figmaProgressHeight = 6;
  static const double _figmaProgressRadius = 99;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(_figmaPaddingH);
    final vertical = context.heightByContext(_figmaPaddingV);
    final thumbSize = context.widthByContext(_figmaThumbSize);
    final clampedProgress = progress.clamp(0, 100);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.widthByContext(_figmaCardRadius)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.widthByContext(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Thumbnail(
                    size: thumbSize,
                    radius: context.widthByContext(_figmaThumbRadius),
                    localImagePath: localImagePath,
                    imageUrl: imageUrl,
                  ),
                  SizedBox(width: context.widthByContext(_figmaRowGap)),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        context.heightByContext(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.heightByContext(_figmaProgressGap)),
              switch (status) {
                ProfilePostUploadStatus.uploading => _UploadingFooter(progress: clampedProgress),
                ProfilePostUploadStatus.success => _StatusFooter(
                  label: successLabel,
                  color: AppColors.primary,
                  icon: Icons.check_circle_rounded,
                ),
                ProfilePostUploadStatus.failure => _StatusFooter(
                  label: statusMessage ?? failureLabel,
                  color: AppColors.error,
                  icon: Icons.error_outline_rounded,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadingFooter extends StatelessWidget {
  const _UploadingFooter({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.widthByContext(ProfilePostUploadProgress._figmaProgressRadius)),
            child: SizedBox(
              height: context.heightByContext(ProfilePostUploadProgress._figmaProgressHeight),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: AppColors.surfaceSoft),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress / 100,
                    child: ColoredBox(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: context.widthByContext(10)),
        Text(
          '$progress/100%',
          style: AppTextStyle.base(
            context.heightByContext(12),
            fontWeight: FontWeight.w700,
            color: AppColors.subTextColor,
          ),
        ),
      ],
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: context.heightByContext(18), color: color),
        SizedBox(width: context.widthByContext(8)),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(
              context.heightByContext(13),
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.size,
    required this.radius,
    this.localImagePath,
    this.imageUrl,
  });

  final double size;
  final double radius;
  final String? localImagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final localPath = localImagePath?.trim();
    final remoteUrl = imageUrl?.trim();

    Widget image;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      image = Image.file(File(localPath), fit: BoxFit.cover);
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      image = Image.network(remoteUrl, fit: BoxFit.cover);
    } else {
      image = ColoredBox(
        color: AppColors.surfaceSoft,
        child: Icon(Icons.image_outlined, size: size * 0.42, color: AppColors.iconMuted),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
