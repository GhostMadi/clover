import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/followers_and_followings/data/models/follow_profile_row.dart';
import 'package:flutter/material.dart';

class FollowProfileTile extends StatelessWidget {
  const FollowProfileTile({
    super.key,
    required this.row,
    required this.showFollowButton,
    required this.onToggleFollow,
    this.onTap,
  });

  final FollowProfileRow row;
  final bool showFollowButton;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onTap;

  static const double _buttonHeight = 36;
  static const double _buttonRadius = 12;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = row.avatarUrl?.trim();

    return AppTile(
      title: row.displayUsername,
      onTap: onTap ?? () {
        context.router.root.push(GuestProfileRoute(userId: row.profileId));
      },
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceSoft,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const Icon(Icons.person, color: AppColors.iconMuted, size: 20)
            : null,
      ),
      trailing: showFollowButton ? _buildFollowButton() : null,
      showDivider: false,
    );
  }

  Widget _buildFollowButton() {
    if (row.isFollowing) {
      return AppOutlinedButton(
        text: '  Отписаться  ',
        height: _buttonHeight,
        borderRadius: _buttonRadius,
        isLoading: row.isFollowUpdating,
        onTap: onToggleFollow,
      );
    }

    return AppButton(
      text: '  Подписаться  ',
      height: _buttonHeight,
      borderRadius: _buttonRadius,
      isLoading: row.isFollowUpdating,
      onTap: onToggleFollow,
    );
  }
}
