import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/work/data/models/work_member.dart';
import 'package:flutter/material.dart';

class WorkMemberAvatar extends StatelessWidget {
  const WorkMemberAvatar({super.key, required this.member});

  final WorkMember member;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = member.avatarUrl?.trim();

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceSoft,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(Icons.person, color: AppColors.iconMuted, size: 20)
          : null,
    );
  }
}

class WorkMemberTile extends StatelessWidget {
  const WorkMemberTile({
    super.key,
    required this.member,
    this.trailing,
    this.onTap,
  });

  final WorkMember member;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppTile(
      title: member.displayName?.trim().isNotEmpty == true ? member.displayName!.trim() : member.displayUsername,
      subtitle: member.displayName?.trim().isNotEmpty == true ? member.displayUsername : null,
      leading: WorkMemberAvatar(member: member),
      trailing: trailing,
      showDivider: false,
      onTap: onTap,
    );
  }
}

class WorkFireButton extends StatelessWidget {
  const WorkFireButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  static const double _height = 36;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    return AppOutlinedButton(
      text: 'Уволить',
      height: _height,
      borderRadius: _radius,
      onTap: onTap,
    );
  }
}

class WorkEmptyState extends StatelessWidget {
  const WorkEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(14, color: AppColors.subTextColor),
          ),
          if (actionLabel != null && actionLabel!.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppButton(
              text: actionLabel!,
              height: 48,
              borderRadius: 14,
              onTap: onAction ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class WorkSectionTitle extends StatelessWidget {
  const WorkSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
