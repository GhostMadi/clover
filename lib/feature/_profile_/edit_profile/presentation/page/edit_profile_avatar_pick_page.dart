import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/_profile_/edit_profile/edit_profile_avatar_flow.dart';
import 'package:clover/feature/_profile_/edit_profile/extension/edit_profile_avatar_router_extension.dart';
import 'package:flutter/material.dart';

@RoutePage()
class EditProfileAvatarPickPage extends StatelessWidget {
  const EditProfileAvatarPickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = EditProfileAvatarFlow.instance;

    return AppImageSelectorPage(
      title: 'Аватар',
      confirmLabel: 'Далее',
      maxSelectionCount: EditProfileAvatarFlow.maxPhotos,
      autoConfirmWhenFull: true,
      onClose: () {
        flow.reset();
        context.router.maybePop();
      },
      onConfirmed: (result) {
        flow.saveSelection(result.assets);
        context.router.pushEditProfileAvatarEditor();
      },
    );
  }
}
