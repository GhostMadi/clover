import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/core/storage/app_progressive_network_image.dart';
import 'package:flutter/material.dart';

/// Обложка и аватар на экране редактирования (только UI).
class EditProfileMediaSection extends StatelessWidget {
  const EditProfileMediaSection({
    super.key,
    this.coverUrl,
    this.coverPreview,
    this.avatarUrl,
    this.avatarPreview,
    this.onChangeCover,
    this.onChangeAvatar,
  });

  final String? coverUrl;
  final AppImageEditorResult? coverPreview;
  final String? avatarUrl;
  final AppImageEditorResult? avatarPreview;
  final VoidCallback? onChangeCover;
  final VoidCallback? onChangeAvatar;

  static const double _coverHeight = 150;
  static const double _coverRadius = 24;
  static const double _avatarRadius = 40;

  @override
  Widget build(BuildContext context) {
    final hPad = context.widthByContext(16);
    final coverRadius = context.widthByContext(_coverRadius);
    final coverHeight = context.heightByContext(_coverHeight);
    final avatarRadius = context.heightByContext(_avatarRadius);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: onChangeCover,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(coverRadius),
              child: SizedBox(
                width: double.infinity,
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CoverImage(
                      coverUrl: coverUrl,
                      coverPreview: coverPreview,
                      coverHeight: coverHeight,
                      borderRadius: coverRadius,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: _MediaActionChip(
                        icon: Icons.photo_camera_outlined,
                        label: _coverLabel(coverUrl, coverPreview),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -avatarRadius,
            child: GestureDetector(
              onTap: onChangeAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.activeColor),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      child: _AvatarImage(
                        avatarUrl: avatarUrl,
                        avatarPreview: avatarPreview,
                        radius: avatarRadius,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.textInverse),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _coverLabel(String? coverUrl, AppImageEditorResult? coverPreview) {
    if (coverPreview != null) return 'Изменить обложку';
    final url = coverUrl?.trim();
    if (url != null && url.isNotEmpty) return 'Изменить обложку';
    return 'Добавить обложку';
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarUrl,
    required this.avatarPreview,
    required this.radius,
  });

  final String? avatarUrl;
  final AppImageEditorResult? avatarPreview;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final preview = avatarPreview;
    if (preview?.previewFile != null) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: AppImageEditPreview(
            imageFile: preview!.previewFile!,
            settings: preview.settings,
            imageWidth: preview.asset.width,
            imageHeight: preview.asset.height,
            backgroundColor: AppColors.surface,
          ),
        ),
      );
    }

    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: NetworkImage(url),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      child: Icon(Icons.person_rounded, size: radius, color: AppColors.iconMuted),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.coverUrl,
    required this.coverPreview,
    required this.coverHeight,
    required this.borderRadius,
  });

  final String? coverUrl;
  final AppImageEditorResult? coverPreview;
  final double coverHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final preview = coverPreview;
    if (preview?.previewFile != null) {
      return AppImageEditPreview(
        imageFile: preview!.previewFile!,
        settings: preview.settings,
        imageWidth: preview.asset.width,
        imageHeight: preview.asset.height,
        borderRadius: borderRadius,
        backgroundColor: AppColors.surface,
      );
    }

    final url = coverUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return AppProgressiveNetworkImage(imageUrl: url, height: coverHeight, fit: BoxFit.cover);
    }

    return ColoredBox(
      color: AppColors.surface,
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.iconMuted),
    );
  }
}

class _MediaActionChip extends StatelessWidget {
  const _MediaActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyle.base(13, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
