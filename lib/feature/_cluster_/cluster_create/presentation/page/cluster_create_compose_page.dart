import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/feature/cluster_create/cluster_create_flow.dart';
import 'package:clover/feature/cluster_create/extension/cluster_create_draft_extension.dart';
import 'package:clover/feature/cluster_create/extension/cluster_create_router_extension.dart';
import 'package:clover/feature/cluster_create/model/cluster_create_compose_result.dart';
import 'package:clover/feature/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart';
import 'package:clover/feature/cluster_create/presentation/widget/cluster_create_step_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@RoutePage()
class ClusterCreateComposePage extends StatefulWidget {
  const ClusterCreateComposePage({super.key});

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaSectionHPadding = 16;
  static const double _figmaSectionGap = 20;
  static const double _figmaPreviewRadius = 16;
  static const double _figmaCloseIconSize = 24;
  static const int _titleMaxLength = 120;
  static const int _descriptionMaxLength = 500;

  @override
  State<ClusterCreateComposePage> createState() => _ClusterCreateComposePageState();
}

class _ClusterCreateComposePageState extends State<ClusterCreateComposePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublishing = false;

  late final _cover = ClusterCreateFlow.instance.draft.editedMedia.first;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canPublish {
    final draft = ClusterCreateFlow.instance.draft;
    return draft.canPublish && _titleController.text.trim().isNotEmpty && !_isPublishing;
  }

  Future<void> _handlePublish() async {
    if (!_canPublish) return;

    FocusScope.of(context).unfocus();
    setState(() => _isPublishing = true);

    final result = ClusterCreateComposeResult(
      cover: _cover,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    sl<ClusterCreateUploadCubit>().publish(result);
    ClusterCreateFlow.instance.reset();

    if (!mounted) return;
    context.router.closeClusterCreateFlow();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(ClusterCreateComposePage._figmaSectionHPadding);
    final previewFile = _cover.previewFile!;

    return ClusterCreateStepGuard(
      canShow: ClusterCreateFlow.instance.draft.canOpenCompose,
      child: Scaffold(
        backgroundColor: AppColors.postEditorBackground,
        appBar: AppBar(
          backgroundColor: AppColors.postEditorBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              size: context.widthByContext(ClusterCreateComposePage._figmaCloseIconSize),
            ),
            color: AppColors.postEditorOnSurface,
            onPressed: () => context.router.maybePop(),
          ),
          title: Text(
            'Кластер',
            style: AppTextStyle.base(
              ClusterCreateComposePage._figmaAppBarTitleFont,
              fontWeight: FontWeight.w700,
              color: AppColors.postEditorOnSurface,
            ),
          ),
          actions: [
            AppTextButton(
              text: 'Создать',
              onTap: _canPublish ? _handlePublish : null,
              isLoading: _isPublishing,
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      context.heightByContext(12),
                      horizontal,
                      context.heightByContext(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: AppImageEditPreview(
                            imageFile: previewFile,
                            settings: _cover.settings,
                            imageWidth: _cover.asset.width,
                            imageHeight: _cover.asset.height,
                            borderRadius: context.widthByContext(ClusterCreateComposePage._figmaPreviewRadius),
                            backgroundColor: AppColors.surfaceSoft,
                          ),
                        ),
                        SizedBox(height: context.heightByContext(ClusterCreateComposePage._figmaSectionGap)),
                        AppField(
                          controller: _titleController,
                          labelText: 'Название',
                          hintText: 'Название кластера',
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(ClusterCreateComposePage._titleMaxLength),
                          ],
                        ),
                        SizedBox(height: context.heightByContext(ClusterCreateComposePage._figmaSectionGap)),
                        AppField(
                          controller: _descriptionController,
                          labelText: 'Описание',
                          hintText: 'Краткое описание (необязательно)',
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(ClusterCreateComposePage._descriptionMaxLength),
                          ],
                        ),
                      ],
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
                  child: AppButton(
                    text: 'Создать кластер',
                    onTap: _canPublish ? _handlePublish : null,
                    isLoading: _isPublishing,
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
