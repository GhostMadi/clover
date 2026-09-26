import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Компактная иконка follow/unfollow в шапке карточки ленты.
class PostFeedFollowIconButton extends StatelessWidget {
  const PostFeedFollowIconButton({
    super.key,
    required this.subscribe,
    required this.isLoading,
    required this.tooltip,
    required this.onTap,
  });

  final bool subscribe;
  final bool isLoading;
  final String tooltip;
  final VoidCallback? onTap;

  static const double _size = 36;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = subscribe ? colors.primary : colors.surfaceSoft;
    final fg = subscribe
        ? (ThemeData.estimateBrightnessForColor(colors.primary) == Brightness.dark
              ? colors.white
              : colors.textColor)
        : colors.textColor;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: subscribe ? BorderSide.none : BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Icon(
                      subscribe ? AppIcons.personAdd.icon : AppIcons.personRemove.icon,
                      size: 20,
                      color: fg,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
