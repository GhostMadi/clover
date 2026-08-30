import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';
import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/location/data/models/location_model.dart';
import 'package:clover/feature/location/presentation/widget/location_single_select_field.dart';
import 'package:clover/feature/marker_tags/presentation/widget/multi_marker_tags.dart';
import 'package:clover/feature/marker_create/extension/marker_create_compose_validation.dart';
import 'package:clover/feature/marker_create/extension/marker_create_draft_extension.dart';
import 'package:clover/feature/marker_create/extension/marker_create_router_extension.dart';
import 'package:clover/feature/marker_create/model/marker_create_compose_result.dart';
import 'package:clover/feature/marker_create/marker_create_flow.dart';
import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_cubit.dart';
import 'package:clover/feature/marker_create/presentation/widget/marker_create_step_guard.dart';
import 'package:clover/feature/settings_filter/presentation/create/widget/post_create_filter_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Финальный шаг: превью + заголовок/описание поста + поля маркера.
@RoutePage()
class MarkerCreateComposePage extends StatefulWidget {
  const MarkerCreateComposePage({super.key});

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaSectionHPadding = 16;
  static const double _figmaSectionGap = 20;
  static const double _figmaPreviewRadius = 16;
  static const double _figmaCloseIconSize = 24;
  static const int _titleMaxLength = 120;
  static const int _descriptionMaxLength = 2000;
  static const int _textEmojiMaxLength = 1;

  @override
  State<MarkerCreateComposePage> createState() => _MarkerCreateComposePageState();
}

class _MarkerCreateComposePageState extends State<MarkerCreateComposePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _textEmojiController = TextEditingController();
  final _previewController = PageController();
  int _previewIndex = 0;
  bool _isSubmitting = false;
  LocationModel? _selectedLocation;
  Set<String> _selectedTagIds = const {};
  Set<String> _selectedFilterValues = const {};
  AppDateTimeRange? _eventPeriod;

  late final List<AppImageEditorResult> _media = List.unmodifiable(MarkerCreateFlow.instance.draft.editedMedia);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _textEmojiController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (!MarkerCreateFlow.instance.draft.canPublish || _isSubmitting) return false;

    final result = MarkerCreateComposeResult(
      media: _media,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      textEmoji: _textEmojiController.text.trim(),
      tagIds: _selectedTagIds,
      filterValues: _selectedFilterValues,
      location: _selectedLocation,
      eventPeriod: _eventPeriod,
    );
    return result.isValid;
  }

  void _handleClose() {
    context.router.maybePop();
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final result = MarkerCreateComposeResult(
      media: _media,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      textEmoji: _textEmojiController.text.trim(),
      tagIds: _selectedTagIds,
      filterValues: _selectedFilterValues,
      location: _selectedLocation,
      eventPeriod: _eventPeriod,
    );

    sl<MarkerCreateUploadCubit>().publish(result);
    MarkerCreateFlow.instance.reset();

    if (!mounted) return;
    context.router.closeMarkerCreateFlow();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(MarkerCreateComposePage._figmaSectionHPadding);

    return MarkerCreateStepGuard(
      canShow: MarkerCreateFlow.instance.draft.canOpenCompose,
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
              size: context.widthByContext(MarkerCreateComposePage._figmaCloseIconSize),
            ),
            color: AppColors.postEditorOnSurface,
            onPressed: _handleClose,
          ),
          title: Text(
            'Маркер',
            style: AppTextStyle.base(
              MarkerCreateComposePage._figmaAppBarTitleFont,
              fontWeight: FontWeight.w700,
              color: AppColors.postEditorOnSurface,
            ),
          ),
          actions: [
            AppTextButton(
              text: 'Создать',
              onTap: _canSubmit ? _handleSubmit : null,
              isLoading: _isSubmitting,
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
                                borderRadius: context.widthByContext(MarkerCreateComposePage._figmaPreviewRadius),
                                backgroundColor: AppColors.surfaceSoft,
                              );
                            },
                          ),
                        ),
                        if (_media.length > 1) ...[
                          SizedBox(height: context.heightByContext(10)),
                          _PreviewDots(count: _media.length, activeIndex: _previewIndex),
                        ],
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        AppField(
                          controller: _titleController,
                          labelText: 'Заголовок',
                          hintText: 'Добавьте заголовок',
                          textInputAction: TextInputAction.next,
                          isEnabled: !_isSubmitting,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(MarkerCreateComposePage._titleMaxLength),
                          ],
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        _DescriptionField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          maxLength: MarkerCreateComposePage._descriptionMaxLength,
                          enabled: !_isSubmitting,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        PostCreateFilterField(
                          values: _selectedFilterValues,
                          enabled: !_isSubmitting,
                          onChanged: (values) => setState(() => _selectedFilterValues = values),
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        AppSmilePicker(
                          controller: _textEmojiController,
                          label: 'Эмодзи маркера',
                          hintText: 'Выберите или введите эмодзи',
                          maxLength: MarkerCreateComposePage._textEmojiMaxLength,
                          enabled: !_isSubmitting,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        MultiMarkerTags(
                          label: 'Теги',
                          hint: 'Выберите теги',
                          values: _selectedTagIds,
                          enabled: !_isSubmitting,
                          onChanged: (ids) => setState(() => _selectedTagIds = ids),
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        LocationSingleSelectField(
                          label: 'Местоположение',
                          hint: 'Выберите местоположение',
                          value: _selectedLocation?.id,
                          enabled: !_isSubmitting,
                          onChanged: (location) => setState(() => _selectedLocation = location),
                        ),
                        SizedBox(height: context.heightByContext(MarkerCreateComposePage._figmaSectionGap)),
                        AppTimePicker(
                          label: 'Период события',
                          hint: 'Выберите начало и конец',
                          value: _eventPeriod,
                          enabled: !_isSubmitting,
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
                    text: 'Создать',
                    onTap: _canSubmit ? _handleSubmit : null,
                    isLoading: _isSubmitting,
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
            color: widget.enabled ? AppColors.fieldBackground : AppColors.fieldBackgroundDisabled,
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
