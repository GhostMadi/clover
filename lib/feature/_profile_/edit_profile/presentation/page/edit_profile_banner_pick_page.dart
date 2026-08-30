import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/_profile_/edit_profile/edit_profile_banner_flow.dart';
import 'package:clover/feature/_profile_/edit_profile/extension/edit_profile_banner_router_extension.dart';
import 'package:flutter/material.dart';

@RoutePage()
class EditProfileBannerPickPage extends StatelessWidget {
  const EditProfileBannerPickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = EditProfileBannerFlow.instance;

    return AppImageSelectorPage(
      title: 'Обложка профиля',
      confirmLabel: 'Далее',
      maxSelectionCount: EditProfileBannerFlow.maxPhotos,
      autoConfirmWhenFull: true,
      onClose: () {
        flow.reset();
        context.router.maybePop();
      },
      onConfirmed: (result) {
        flow.saveSelection(result.assets);
        context.router.pushEditProfileBannerEditor();
      },
    );
  }
}
