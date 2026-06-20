import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/edit_profile/data/edit_profile_username_policy.dart';
import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';
import 'package:flutter/material.dart';

class EditProfileUsernameRow extends StatelessWidget {
  const EditProfileUsernameRow({
    super.key,
    required this.profile,
    required this.username,
    required this.onTap,
  });

  final ProfileNewModel profile;
  final String username;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final policy = EditProfileUsernamePolicy.fromProfile(profile);
    final value = username.trim();
    final display = value.isEmpty ? 'Не задан' : (value.startsWith('@') ? value : '@$value');
    final subtitle = policy.statusHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Никнейм',
            style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: AppColors.fieldLabel),
          ),
        ),
        AppTile(
          title: display,
          subtitle: subtitle,
          icon: Icons.alternate_email_rounded,
          showChevron: policy.canChange,
          filled: true,
          onTap: policy.canChange ? onTap : null,
          enabled: policy.canChange,
        ),
      ],
    );
  }
}
