import 'package:auto_route/auto_route.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/image_select/app_image_editor_page.dart';
import 'package:clover/feature/edit_profile/edit_profile_avatar_flow.dart';
import 'package:clover/feature/edit_profile/extension/edit_profile_avatar_router_extension.dart';
import 'package:clover/feature/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class EditProfileAvatarEditorPage extends StatelessWidget {
  const EditProfileAvatarEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = EditProfileAvatarFlow.instance;
    final draft = flow.draft;

    return PostCreateStepGuard(
      canShow: draft.canOpenEditor,
      child: AppImageEditorPage(
        assets: draft.selectedAssets,
        title: 'Аватар',
        confirmLabel: 'Далее',
        lockedAspectRatio: PostAspectRatio.square1x1,
        onClose: () => context.router.maybePop(),
        onDone: (results) {
          flow.saveEditedMedia(results);
          context.router.pushEditProfileAvatarConfirm();
        },
      ),
    );
  }
}
