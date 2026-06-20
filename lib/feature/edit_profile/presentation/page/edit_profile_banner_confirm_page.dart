import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/edit_profile/edit_profile_banner_flow.dart';
import 'package:clover/feature/edit_profile/extension/edit_profile_banner_draft_extension.dart';
import 'package:clover/feature/edit_profile/extension/edit_profile_banner_router_extension.dart';
import 'package:clover/feature/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class EditProfileBannerConfirmPage extends StatelessWidget {
  const EditProfileBannerConfirmPage({super.key});

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaSectionHPadding = 16;
  static const double _figmaPreviewRadius = 16;
  static const double _figmaCloseIconSize = 24;

  @override
  Widget build(BuildContext context) {
    final flow = EditProfileBannerFlow.instance;
    final draft = flow.draft;
    final cover = draft.editedMedia.isNotEmpty ? draft.editedMedia.first : null;

    return PostCreateStepGuard(
      canShow: draft.canOpenConfirm && cover != null,
      child: _EditProfileBannerConfirmBody(cover: cover!),
    );
  }
}

class _EditProfileBannerConfirmBody extends StatelessWidget {
  const _EditProfileBannerConfirmBody({required this.cover});

  final AppImageEditorResult cover;

  void _accept(BuildContext context) {
    EditProfileBannerFlow.instance.complete(cover);
    context.router.closeEditProfileBannerFlow();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(EditProfileBannerConfirmPage._figmaSectionHPadding);
    final previewFile = cover.previewFile!;

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
            size: context.widthByContext(EditProfileBannerConfirmPage._figmaCloseIconSize),
          ),
          color: AppColors.postEditorOnSurface,
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Обложка',
          style: AppTextStyle.base(
            EditProfileBannerConfirmPage._figmaAppBarTitleFont,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: AspectRatio(
                    aspectRatio: cover.settings.aspectRatio.ratio,
                    child: AppImageEditPreview(
                      imageFile: previewFile,
                      settings: cover.settings,
                      imageWidth: cover.asset.width,
                      imageHeight: cover.asset.height,
                      borderRadius: context.widthByContext(EditProfileBannerConfirmPage._figmaPreviewRadius),
                      backgroundColor: AppColors.surfaceSoft,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
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
