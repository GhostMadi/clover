import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/post_create/extension/post_create_draft_extension.dart';
import 'package:clover/feature/post_create/extension/post_create_router_extension.dart';
import 'package:clover/feature/post_create/model/post_create_compose_result.dart';
import 'package:clover/feature/post_create/post_create_flow.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:clover/feature/settings_filter/presentation/create/widget/post_create_filter_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Финальный шаг создания поста: превью + заголовок + описание.
@RoutePage()
class PostCreateComposePage extends StatefulWidget {
  const PostCreateComposePage({super.key});

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaSectionHPadding = 16;
  static const double _figmaSectionGap = 20;
  static const double _figmaPreviewRadius = 16;
  static const double _figmaCloseIconSize = 24;
  static const int _titleMaxLength = 120;
  static const int _descriptionMaxLength = 2000;

  @override
  State<PostCreateComposePage> createState() => _PostCreateComposePageState();
}

class _PostCreateComposePageState extends State<PostCreateComposePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _previewController = PageController();
  int _previewIndex = 0;
  bool _isPublishing = false;
  Set<String> _selectedFilterValues = const {};

  late final List<AppImageEditorResult> _media = List.unmodifiable(PostCreateFlow.instance.draft.editedMedia);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _previewController.dispose();
    super.dispose();
  }

  bool get _canPublish => PostCreateFlow.instance.draft.canPublish && !_isPublishing;

  void _handleClose() {
    context.router.maybePop();
  }

  Future<void> _handlePublish() async {
    if (!_canPublish) return;

    FocusScope.of(context).unfocus();
    setState(() => _isPublishing = true);

    final result = PostCreateComposeResult(
      media: _media,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      filterValues: _selectedFilterValues,
    );

    sl<PostCreateUploadCubit>().publish(result);
    PostCreateFlow.instance.reset();

    if (!mounted) return;
    context.router.closePostCreateFlow();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(PostCreateComposePage._figmaSectionHPadding);

    return PostCreateStepGuard(
      canShow: PostCreateFlow.instance.draft.canOpenCompose,
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
              size: context.widthByContext(PostCreateComposePage._figmaCloseIconSize),
            ),
            color: AppColors.postEditorOnSurface,
            onPressed: _handleClose,
          ),
          title: Text(
            'Публикация',
            style: AppTextStyle.base(
              PostCreateComposePage._figmaAppBarTitleFont,
              fontWeight: FontWeight.w700,
              color: AppColors.postEditorOnSurface,
            ),
          ),
          actions: [
            AppTextButton(
              text: 'Опубликовать',
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
                          aspectRatio: _media.previewAspectRatioAt(_previewIndex),
                          child: PageView.builder(
                            controller: _previewController,
                            itemCount: _media.length,
                            onPageChanged: (index) => setState(() => _previewIndex = index),
                            itemBuilder: (context, index) {
                              final item = _media[index];
                              final file = item.previewFile!;

                              return AppImageEditPreview(
                                imageFile: file,
                                settings: item.settings,
                                imageWidth: item.asset.width,
                                imageHeight: item.asset.height,
                                borderRadius: context.widthByContext(PostCreateComposePage._figmaPreviewRadius),
                                backgroundColor: AppColors.surfaceSoft,
                              );
                            },
                          ),
                        ),
                        if (_media.length > 1) ...[
                          SizedBox(height: context.heightByContext(10)),
                          _PreviewDots(
                            count: _media.length,
                            activeIndex: _previewIndex,
                          ),
                        ],
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        AppField(
                          controller: _titleController,
                          labelText: 'Заголовок',
                          hintText: 'Добавьте заголовок',
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(PostCreateComposePage._titleMaxLength),
                          ],
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        _DescriptionField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          maxLength: PostCreateComposePage._descriptionMaxLength,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        PostCreateFilterField(
                          values: _selectedFilterValues,
                          enabled: !_isPublishing,
                          onChanged: (values) => setState(() => _selectedFilterValues = values),
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
                    text: 'Опубликовать',
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

class _PreviewDots extends StatelessWidget {
  const _PreviewDots({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _DescriptionField extends StatefulWidget {
  const _DescriptionField({
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused ? AppColors.fieldBorderFocused : AppColors.fieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Описание',
            style: AppTextStyle.base(
              13,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppColors.fieldLabelFocused : AppColors.fieldLabel,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isFocused ? 1.6 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.fieldShadowFocused.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.shadowDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: widget.onChanged,
            maxLines: 6,
            minLines: 4,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            style: AppTextStyle.base(
              16,
              fontWeight: FontWeight.w500,
              color: AppColors.fieldText,
              height: 1.45,
            ),
            cursorColor: AppColors.fieldCursor,
            decoration: InputDecoration(
              hintText: 'Расскажите о публикации',
              hintStyle: AppTextStyle.base(16, fontWeight: FontWeight.w400, color: AppColors.fieldHint),
              border: InputBorder.none,
              counterStyle: AppTextStyle.base(12, color: AppColors.subTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
