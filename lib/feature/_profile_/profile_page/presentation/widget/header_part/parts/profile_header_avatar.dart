import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Аватар профиля с обводкой.
class ProfileHeaderAvatar extends StatelessWidget {
  const ProfileHeaderAvatar({super.key, this.imageUrl});

  final String? imageUrl;

  static const double _figmaOuterPadding = 3;
  static const double _figmaInnerPadding = 2;
  static const double _figmaRadius = 40;
  static const double _figmaIconSize = 44;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;
    final radius = context.heightByContext(_figmaRadius);
    final iconSize = context.heightByContext(_figmaIconSize);

    return Container(
      padding: EdgeInsets.all(context.widthByContext(_figmaOuterPadding)),
      decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.activeColor),
      child: Container(
        padding: EdgeInsets.all(context.widthByContext(_figmaInnerPadding)),
        decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: context.colors.surface,
          backgroundImage: hasImage ? NetworkImage(url) : null,
          child: hasImage
              ? null
              : Icon(AppIcons.personRounded.icon, size: iconSize, color: context.colors.iconMuted),
        ),
      ),
    );
  }
}
