import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:flutter/material.dart';

/// Аватар + имя автора поста; тап открывает [GuestProfileRoute].
class PostAuthorHeader extends StatelessWidget {
  const PostAuthorHeader({
    super.key,
    required this.userId,
    this.username,
    this.avatarUrl,
    this.trailing,
    this.avatarRadius = 22,
    this.usernamePrefix,
  });

  final String userId;
  final String? username;
  final String? avatarUrl;
  final Widget? trailing;
  final double avatarRadius;
  final String? usernamePrefix;

  void _openProfile(BuildContext context) {
    final id = userId.trim();
    if (id.isEmpty) return;
    context.router.push(GuestProfileRoute(userId: id));
  }

  @override
  Widget build(BuildContext context) {
    final name = username?.trim();
    final photo = avatarUrl?.trim();
    final label = name != null && name.isNotEmpty
        ? '${usernamePrefix ?? ''}$name'
        : (usernamePrefix != null ? 'Автор' : 'noName');

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openProfile(context),
            borderRadius: BorderRadius.circular(avatarRadius + 6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(avatarRadius + 4),
                border: Border.all(color: context.colors.borderSoft),
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: context.colors.surfaceSoft,
                backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo == null || photo.isEmpty
                    ? Icon(AppIcons.user.icon, color: context.colors.iconMuted, size: avatarRadius)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openProfile(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
