import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/edit_profile/edit_profile_avatar_flow.dart';
import 'package:clover/feature/edit_profile/extension/edit_profile_avatar_draft_extension.dart';
import 'package:clover/feature/edit_profile/extension/edit_profile_avatar_router_extension.dart';
import 'package:clover/feature/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class EditProfileAvatarConfirmPage extends StatelessWidget {
  const EditProfileAvatarConfirmPage({super.key});

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaPreviewSize = 280;
  static const double _figmaCloseIconSize = 24;

  @override
  Widget build(BuildContext context) {
    final flow = EditProfileAvatarFlow.instance;
    final draft = flow.draft;
    final avatar = draft.editedMedia.isNotEmpty ? draft.editedMedia.first : null;

    return PostCreateStepGuard(
      canShow: draft.canOpenConfirm && avatar != null,
      child: _EditProfileAvatarConfirmBody(avatar: avatar!),
    );
  }
}

class _EditProfileAvatarConfirmBody extends StatelessWidget {
  const _EditProfileAvatarConfirmBody({required this.avatar});

  final AppImageEditorResult avatar;

  void _accept(BuildContext context) {
    EditProfileAvatarFlow.instance.complete(avatar);
    context.router.closeEditProfileAvatarFlow();
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = avatar.previewFile!;
    final previewSize = context.widthByContext(EditProfileAvatarConfirmPage._figmaPreviewSize);

    return Scaffold(
      backgroundColor: AppColors.postEditorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.postEditorBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: context.widthByContext(EditProfileAvatarConfirmPage._figmaCloseIconSize),
          ),
          color: AppColors.postEditorOnSurface,
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Аватар',
          style: AppTextStyle.base(
            EditProfileAvatarConfirmPage._figmaAppBarTitleFont,
            fontWeight: FontWeight.w700,
            color: AppColors.postEditorOnSurface,
          ),
        ),
        actions: [
          AppTextButton(text: 'Принять', onTap: () => _accept(context)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: previewSize,
                  height: previewSize,
                  child: ClipOval(
                    child: AppImageEditPreview(
                      imageFile: previewFile,
                      settings: avatar.settings,
                      imageWidth: avatar.asset.width,
                      imageHeight: avatar.asset.height,
                      backgroundColor: AppColors.surfaceSoft,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                context.heightByContext(16) + MediaQuery.paddingOf(context).bottom,
              ),
              child: AppButton(text: 'Принять', isExpanded: true, onTap: () => _accept(context)),
            ),
          ],
        ),
      ),
    );
  }
}
