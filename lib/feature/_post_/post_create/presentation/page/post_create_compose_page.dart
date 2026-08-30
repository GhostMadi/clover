import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/presentation/widget/location_single_select_field.dart';
import 'package:clover/feature/_catalog_/marker_tags/presentation/widget/multi_marker_tags.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_compose_validation.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_draft_extension.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_router_extension.dart';
import 'package:clover/feature/_post_/post_create/model/post_create_compose_result.dart';
import 'package:clover/feature/_post_/post_create/post_create_flow.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/create/widget/post_create_filter_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Финальный шаг: превью + поля публикации и маркера на карте.
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
  static const int _textEmojiMaxLength = 1;

  @override
  State<PostCreateComposePage> createState() => _PostCreateComposePageState();
}

class _PostCreateComposePageState extends State<PostCreateComposePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _textEmojiController = TextEditingController();
  final _previewController = PageController();
  int _previewIndex = 0;
  bool _isPublishing = false;
  LocationModel? _selectedLocation;
  Set<String> _selectedTagIds = const {};
  Set<String> _selectedFilterValues = const {};
  AppDateTimeRange? _eventPeriod;

  late final List<AppImageEditorResult> _media = List.unmodifiable(PostCreateFlow.instance.draft.editedMedia);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _textEmojiController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  PostCreateComposeResult get _composeResult => PostCreateComposeResult(
        media: _media,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        textEmoji: _textEmojiController.text.trim(),
        tagIds: _selectedTagIds,
        filterValues: _selectedFilterValues,
        location: _selectedLocation,
        eventPeriod: _eventPeriod,
      );

  bool get _isEventMode => _eventPeriod != null;

  bool get _canPublish => PostCreateFlow.instance.draft.canPublish && !_isPublishing;

  void _handleClose() {
    context.router.maybePop();
  }

  Future<void> _handlePublish() async {
    if (_isPublishing) return;

    final blockReason = _composeResult.publishBlockReason;
    if (blockReason != null) {
      AppSnackBar.show(context, message: blockReason, kind: AppSnackBarKind.error);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPublishing = true);

    sl<PostCreateUploadCubit>().publish(_composeResult);
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
        backgroundColor: context.colors.postEditorBackground,
        appBar: AppBar(
          backgroundColor: context.colors.postEditorBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              AppIcons.arrowBackRounded.icon,
              size: context.widthByContext(PostCreateComposePage._figmaCloseIconSize),
            ),
            color: context.colors.postEditorOnSurface,
            onPressed: _handleClose,
          ),
          title: Text(
            'Публикация',
            style: AppTextStyle.base(
              PostCreateComposePage._figmaAppBarTitleFont,
              fontWeight: FontWeight.w700,
              color: context.colors.postEditorOnSurface,
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
                                backgroundColor: context.colors.surfaceSoft,
                              );
                            },
                          ),
                        ),
                        if (_media.length > 1) ...[
                          SizedBox(height: context.heightByContext(10)),
                          _PreviewDots(count: _media.length, activeIndex: _previewIndex),
                        ],
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        AppField(
                          controller: _titleController,
                          labelText: 'Заголовок',
                          hintText: 'Добавьте заголовок',
                          textInputAction: TextInputAction.next,
                          isEnabled: !_isPublishing,
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
                          enabled: !_isPublishing,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        PostCreateFilterField(
                          values: _selectedFilterValues,
                          enabled: !_isPublishing,
                          onChanged: (values) => setState(() => _selectedFilterValues = values),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        AppSmilePicker(
                          controller: _textEmojiController,
                          label: 'Эмодзи',
                          hintText: 'Добавьте эмодзи',
                          maxLength: PostCreateComposePage._textEmojiMaxLength,
                          enabled: !_isPublishing,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        MultiMarkerTags(
                          label: 'Теги',
                          hint: 'Выберите теги',
                          values: _selectedTagIds,
                          enabled: !_isPublishing,
                          onChanged: (ids) => setState(() => _selectedTagIds = ids),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        LocationSingleSelectField(
                          label: 'Местоположение',
                          hint: 'Выберите местоположение',
                          value: _selectedLocation?.id,
                          enabled: !_isPublishing,
                          onChanged: (location) => setState(() => _selectedLocation = location),
                        ),
                        SizedBox(height: context.heightByContext(PostCreateComposePage._figmaSectionGap)),
                        AppTimePicker(
                          label: 'Период события',
                          hint: _isEventMode
                              ? 'Ивент на карте — укажите начало и конец'
                              : 'Необязательно — без периода обычная публикация',
                          value: _eventPeriod,
                          enabled: !_isPublishing,
                          onChanged: (range) => setState(() => _eventPeriod = range),
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
            color: isActive ? context.colors.primary : context.colors.border,
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool enabled;

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
    final borderColor = _isFocused ? context.colors.fieldBorderFocused : context.colors.fieldBorder;

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
              color: _isFocused ? context.colors.fieldLabelFocused : context.colors.fieldLabel,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled ? context.colors.fieldBackground : context.colors.fieldBackgroundDisabled,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isFocused ? 1.6 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: context.colors.fieldShadowFocused.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: context.colors.shadowDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            maxLines: 6,
            minLines: 4,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            style: AppTextStyle.base(
              16,
              fontWeight: FontWeight.w500,
              color: context.colors.fieldText,
              height: 1.45,
            ),
            cursorColor: context.colors.fieldCursor,
            decoration: InputDecoration(
              hintText: 'Расскажите о публикации',
              hintStyle: AppTextStyle.base(16, fontWeight: FontWeight.w400, color: context.colors.fieldHint),
              border: InputBorder.none,
              counterStyle: AppTextStyle.base(12, color: context.colors.subTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
