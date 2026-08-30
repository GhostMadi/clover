import 'dart:io';

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/app_image_crop_math.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:clover/core/shared/image_select/extension/asset_entity_list_extension.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

export 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';

/// Переиспользуемый экран редактирования фото: эффекты + ручная настройка (как в Instagram).
class AppImageEditorPage extends StatefulWidget {
  const AppImageEditorPage({
    super.key,
    required this.assets,
    this.title = 'Редактирование',
    this.confirmLabel = 'Далее',
    this.lockedAspectRatio,
    this.onClose,
    this.onDone,
  });

  final List<AssetEntity> assets;
  final String title;
  final String confirmLabel;

  /// Если задан — формат фиксирован (например 1:1 для обложки кластера).
  final PostAspectRatio? lockedAspectRatio;
  final VoidCallback? onClose;
  final ValueChanged<List<AppImageEditorResult>>? onDone;

  static const double _figmaPanelContentHeight = 148;
  static const double _figmaAspectFrameHeight = 56;
  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaPanelHPadding = 16;
  static const double _figmaPanelVPadding = 12;
  static const double _figmaToolIconSize = 22;
  static const double _figmaToolLabelFont = 11;
  static const double _figmaEffectThumbSize = 64;
  static const double _figmaEffectLabelFont = 11;
  static const double _figmaSliderLabelFont = 13;
  static const double _figmaCloseIconSize = 24;
  static const double _figmaThumbSize = 56;

  @override
  State<AppImageEditorPage> createState() => _AppImageEditorPageState();
}

class _AppImageEditorPageState extends State<AppImageEditorPage> {
  late List<AppImageEditSettings> _settingsList;
  late List<File?> _filesList;
  int _currentIndex = 0;
  int _panelIndex = 0;
  AppImageEditTool _activeTool = AppImageEditTool.brightness;
  bool _isLoading = true;

  AppImageEditSettings get _settings => _settingsList[_currentIndex];
  AssetEntity get _currentAsset => widget.assets[_currentIndex];
  File? get _imageFile => _filesList[_currentIndex];

  @override
  void initState() {
    super.initState();
    final initial = widget.lockedAspectRatio != null
        ? AppImageEditSettings(aspectRatio: widget.lockedAspectRatio!)
        : AppImageEditSettings.none;
    _settingsList = List.filled(widget.assets.length, initial);
    _filesList = List.filled(widget.assets.length, null);
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final files = await widget.assets.loadFiles();

      if (!mounted) return;

      setState(() {
        for (var i = 0; i < files.length; i++) {
          _filesList[i] = files[i];
        }
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('AppImageEditorPage: failed to load assets: $error\n$stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setSettings(AppImageEditSettings value) {
    _settingsList[_currentIndex] = value;
  }

  void _selectIndex(int index) {
    if (index == _currentIndex || index < 0 || index >= widget.assets.length) return;

    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _handleDone() {
    final results = <AppImageEditorResult>[];
    for (var i = 0; i < widget.assets.length; i++) {
      final file = _filesList[i];
      if (file == null) return;

      results.add(
        AppImageEditorResult(
          asset: widget.assets[i],
          settings: _settingsList[i],
          previewFile: file,
        ),
      );
    }

    widget.onDone?.call(results);
  }

  void _updateCrop({
    required double scale,
    required Offset offset,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    setState(
      () => _setSettings(
        _settings.copyWith(
          cropScale: scale,
          cropOffset: offset,
          cropViewportWidth: viewportWidth,
          cropViewportHeight: viewportHeight,
        ),
      ),
    );
  }

  double _toolValue(AppImageEditTool tool) => tool.readValue(_settings).clamp(-1.0, 1.0);

  void _updateTool(AppImageEditTool tool, double value) {
    setState(() => _setSettings(tool.writeValue(_settings, value.clamp(-1.0, 1.0))));
  }

  void _selectEffect(String effectId) {
    HapticFeedback.selectionClick();
    setState(() => _setSettings(_settings.copyWith(effectId: effectId)));
  }

  void _selectAspectRatio(PostAspectRatio aspectRatio) {
    if (widget.lockedAspectRatio != null) return;
    if (aspectRatio == _settings.aspectRatio) return;

    HapticFeedback.selectionClick();
    setState(
      () => _setSettings(
        _settings.copyWith(
          aspectRatio: aspectRatio,
          cropScale: AppImageCropMath.minUserScale,
          cropOffset: Offset.zero,
          cropViewportWidth: 0,
          cropViewportHeight: 0,
        ),
      ),
    );
  }

  bool get _allFilesReady => _filesList.every((file) => file != null);

  String get _titleText {
    if (widget.assets.length <= 1) return widget.title;
    return '${widget.title} (${_currentIndex + 1}/${widget.assets.length})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.postEditorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.postEditorBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: context.widthByContext(AppImageEditorPage._figmaCloseIconSize)),
          color: AppColors.postEditorOnSurface,
          onPressed: _handleClose,
        ),
        title: Text(
          _titleText,
          style: AppTextStyle.base(
            AppImageEditorPage._figmaAppBarTitleFont,
            fontWeight: FontWeight.w700,
            color: AppColors.postEditorOnSurface,
          ),
        ),
        actions: [
          AppTextButton(
            text: widget.confirmLabel,
            onTap: _allFilesReady ? _handleDone : null,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.postEditorCta))
          : !_allFilesReady
          ? Center(
              child: Text(
                'Не удалось загрузить фото',
                style: AppTextStyle.base(15, color: AppColors.postEditorOnSurfaceMuted),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: AppColors.surfaceSoft,
                    child: Stack(
                      children: [
                        Center(
                          child: _EditableCropPreview(
                            key: ValueKey(_currentAsset.id),
                            imageFile: _imageFile!,
                            imageWidth: _currentAsset.width,
                            imageHeight: _currentAsset.height,
                            settings: _settings,
                            onCropChanged: _updateCrop,
                          ),
                        ),
                        if (widget.assets.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: context.heightByContext(12),
                            child: SizedBox(
                              height: context.heightByContext(AppImageEditorPage._figmaThumbSize),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.widthByContext(16),
                                ),
                                itemCount: widget.assets.length,
                                separatorBuilder: (_, __) => SizedBox(width: context.widthByContext(8)),
                                itemBuilder: (context, index) {
                                  final asset = widget.assets[index];
                                  final isActive = index == _currentIndex;
                                  final size = context.widthByContext(AppImageEditorPage._figmaThumbSize);

                                  return GestureDetector(
                                    onTap: () => _selectIndex(index),
                                    child: SizedBox(
                                      width: size,
                                      height: size,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isActive ? AppColors.postEditorCta : AppColors.border,
                                            width: isActive ? 2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: AssetEntityImage(
                                            asset,
                                            isOriginal: false,
                                            thumbnailSize: const ThumbnailSize(120, 120),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (_panelIndex == 2 && widget.lockedAspectRatio == null)
                          Positioned(
                            left: context.widthByContext(16),
                            right: context.widthByContext(16),
                            bottom: context.heightByContext(12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.postEditorPanel.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.widthByContext(12),
                                  vertical: context.heightByContext(8),
                                ),
                                child: Text(
                                  'Сжимайте и перемещайте фото в рамке',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.base(
                                    12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.postEditorOnSurfaceMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _EditorPanel(
                  panelIndex: _panelIndex,
                  settings: _settings,
                  activeTool: _activeTool,
                  toolValue: _toolValue(_activeTool),
                  imageFile: _imageFile!,
                  showAspectPanel: widget.lockedAspectRatio == null,
                  onPanelChanged: (index) => setState(() => _panelIndex = index),
                  onToolSelected: (tool) => setState(() => _activeTool = tool),
                  onToolChanged: _updateTool,
                  onEffectSelected: _selectEffect,
                  onAspectRatioSelected: _selectAspectRatio,
                ),
              ],
            ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.panelIndex,
    required this.settings,
    required this.activeTool,
    required this.toolValue,
    required this.imageFile,
    required this.showAspectPanel,
    required this.onPanelChanged,
    required this.onToolSelected,
    required this.onToolChanged,
    required this.onEffectSelected,
    required this.onAspectRatioSelected,
  });

  final int panelIndex;
  final AppImageEditSettings settings;
  final AppImageEditTool activeTool;
  final double toolValue;
  final File imageFile;
  final bool showAspectPanel;
  final ValueChanged<int> onPanelChanged;
  final ValueChanged<AppImageEditTool> onToolSelected;
  final void Function(AppImageEditTool tool, double value) onToolChanged;
  final ValueChanged<String> onEffectSelected;
  final ValueChanged<PostAspectRatio> onAspectRatioSelected;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.widthByContext(AppImageEditorPage._figmaPanelHPadding);
    final vertical = context.heightByContext(AppImageEditorPage._figmaPanelVPadding);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.postEditorPanel,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: context.heightByContext(AppImageEditorPage._figmaPanelContentHeight),
                child: switch (panelIndex) {
                  0 => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activeTool.label,
                              style: AppTextStyle.base(
                                AppImageEditorPage._figmaSliderLabelFont,
                                fontWeight: FontWeight.w600,
                                color: AppColors.postEditorOnSurface,
                              ),
                            ),
                          ),
                          Text(
                            _formatSliderValue(toolValue),
                            style: AppTextStyle.base(
                              AppImageEditorPage._figmaSliderLabelFont,
                              fontWeight: FontWeight.w700,
                              color: AppColors.postEditorCta,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.postEditorCta,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.postEditorCta,
                          overlayColor: AppColors.postEditorSliderOverlay,
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: toolValue,
                          min: -1,
                          max: 1,
                          onChanged: (value) => onToolChanged(activeTool, value),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _AdjustToolsRow(
                            activeTool: activeTool,
                            onToolSelected: onToolSelected,
                          ),
                        ),
                      ),
                    ],
                  ),
                  1 => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppImageEffect.presets.length,
                    separatorBuilder: (_, __) => SizedBox(width: context.widthByContext(10)),
                    itemBuilder: (context, index) {
                      final effect = AppImageEffect.presets[index];
                      final selected = settings.effectId == effect.id;
                      final rowHeight = context.heightByContext(
                        AppImageEditorPage._figmaEffectThumbSize + 24,
                      );

                      return _EffectChip(
                        height: rowHeight,
                        effect: effect,
                        selected: selected,
                        imageFile: imageFile,
                        onTap: () => onEffectSelected(effect.id),
                      );
                    },
                  ),
                  _ => _AspectRatioRow(
                    selected: settings.aspectRatio,
                    onSelected: onAspectRatioSelected,
                  ),
                },
              ),
              SizedBox(height: context.heightByContext(12)),
              AppTab(
                tabs: showAspectPanel
                    ? const ['Настройка', 'Эффекты', 'Формат']
                    : const ['Настройка', 'Эффекты'],
                currentIndex: panelIndex,
                onTabChanged: onPanelChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSliderValue(double value) {
    final percent = (value * 100).round();
    if (percent > 0) return '+$percent';
    return '$percent';
  }
}

class _AdjustToolsRow extends StatelessWidget {
  const _AdjustToolsRow({
    required this.activeTool,
    required this.onToolSelected,
  });

  final AppImageEditTool activeTool;
  final ValueChanged<AppImageEditTool> onToolSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: AppImageEditTool.values.map((tool) {
        final selected = tool == activeTool;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onToolSelected(tool);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.postEditorSliderOverlay : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.widthByContext(8)),
                    child: Icon(
                      tool.icon,
                      size: context.widthByContext(AppImageEditorPage._figmaToolIconSize),
                      color: selected ? AppColors.postEditorCta : AppColors.postEditorOnSurfaceDim,
                    ),
                  ),
                ),
                SizedBox(height: context.heightByContext(4)),
                Text(
                  tool.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(
                    AppImageEditorPage._figmaToolLabelFont,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.postEditorOnSurface : AppColors.postEditorOnSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({
    required this.height,
    required this.effect,
    required this.selected,
    required this.imageFile,
    required this.onTap,
  });

  final double height;
  final AppImageEffect effect;
  final bool selected;
  final File imageFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = context.widthByContext(AppImageEditorPage._figmaEffectThumbSize);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: width,
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                width: width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.postEditorCta : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(effect.matrix),
                  child: Image.file(imageFile, fit: BoxFit.cover, width: width),
                ),
              ),
            ),
            SizedBox(height: context.heightByContext(4)),
            Text(
              effect.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(
                AppImageEditorPage._figmaEffectLabelFont,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.postEditorOnSurface : AppColors.postEditorOnSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableCropPreview extends StatefulWidget {
  const _EditableCropPreview({
    super.key,
    required this.imageFile,
    required this.imageWidth,
    required this.imageHeight,
    required this.settings,
    required this.onCropChanged,
  });

  final File imageFile;
  final int imageWidth;
  final int imageHeight;
  final AppImageEditSettings settings;
  final void Function({
    required double scale,
    required Offset offset,
    required double viewportWidth,
    required double viewportHeight,
  }) onCropChanged;

  @override
  State<_EditableCropPreview> createState() => _EditableCropPreviewState();
}

class _EditableCropPreviewState extends State<_EditableCropPreview> {
  late double _scale;
  late Offset _offset;
  double _startScale = AppImageCropMath.minUserScale;
  bool _isGesturing = false;

  @override
  void initState() {
    super.initState();
    _scale = widget.settings.cropScale;
    _offset = widget.settings.cropOffset;
  }

  @override
  void didUpdateWidget(_EditableCropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isGesturing) return;

    if (oldWidget.settings.aspectRatio != widget.settings.aspectRatio ||
        oldWidget.settings.cropScale != widget.settings.cropScale ||
        oldWidget.settings.cropOffset != widget.settings.cropOffset) {
      _scale = widget.settings.cropScale;
      _offset = widget.settings.cropOffset;
    }
  }

  ({double width, double height}) _imageSize(Size viewport) {
    var imageWidth = widget.imageWidth.toDouble();
    var imageHeight = widget.imageHeight.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0) {
      imageWidth = viewport.width;
      imageHeight = viewport.height;
    }
    return (width: imageWidth, height: imageHeight);
  }

  void _applyTransform({
    required Size viewport,
    required double userScale,
    required Offset offset,
    required bool notifyParent,
  }) {
    final image = _imageSize(viewport);
    final clamped = AppImageCropMath.clampTransform(
      userScale: userScale,
      offset: offset,
      viewportWidth: viewport.width,
      viewportHeight: viewport.height,
      imageWidth: image.width,
      imageHeight: image.height,
    );

    setState(() {
      _scale = clamped.scale;
      _offset = clamped.offset;
    });

    if (notifyParent) {
      widget.onCropChanged(
        scale: clamped.scale,
        offset: clamped.offset,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _isGesturing = true;
    _startScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size viewport) {
    final isPinching = details.pointerCount >= 2;

    var nextScale = _scale;
    if (isPinching) {
      nextScale = AppImageCropMath.clampUserScale(_startScale * details.scale);
    }

    // focalPointDelta — приращение с прошлого кадра, накапливаем на текущий offset.
    var nextOffset = _offset + details.focalPointDelta;

    if (isPinching && nextScale != _scale) {
      final focal = details.localFocalPoint;
      final center = Offset(viewport.width / 2, viewport.height / 2);
      final scaleRatio = nextScale / _scale;
      nextOffset = nextOffset + (focal - center) * (1 - scaleRatio);
    }

    _applyTransform(
      viewport: viewport,
      userScale: nextScale,
      offset: nextOffset,
      notifyParent: false,
    );
  }

  void _handleScaleEnd(ScaleEndDetails details, Size viewport) {
    _isGesturing = false;
    _applyTransform(
      viewport: viewport,
      userScale: _scale,
      offset: _offset,
      notifyParent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.settings.aspectRatio.ratio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final image = _imageSize(viewport);

          final clamped = AppImageCropMath.clampTransform(
            userScale: _scale,
            offset: _offset,
            viewportWidth: viewport.width,
            viewportHeight: viewport.height,
            imageWidth: image.width,
            imageHeight: image.height,
          );

          final render = AppImageCropMath.renderSize(
            viewportWidth: viewport.width,
            viewportHeight: viewport.height,
            imageWidth: image.width,
            imageHeight: image.height,
            userScale: clamped.scale,
          );

          return ClipRect(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: (details) => _handleScaleUpdate(details, viewport),
              onScaleEnd: (details) => _handleScaleEnd(details, viewport),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: (viewport.width - render.width) / 2 + clamped.offset.dx,
                    top: (viewport.height - render.height) / 2 + clamped.offset.dy,
                    width: render.width,
                    height: render.height,
                    child: ColorFiltered(
                      colorFilter: widget.settings.colorFilter,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.fill,
                        width: render.width,
                        height: render.height,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AspectRatioRow extends StatelessWidget {
  const _AspectRatioRow({
    required this.selected,
    required this.onSelected,
  });

  final PostAspectRatio selected;
  final ValueChanged<PostAspectRatio> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PostAspectRatio.values.map((ratio) {
        final isSelected = ratio == selected;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(ratio),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AspectRatioFrame(
                  ratio: ratio.ratio,
                  selected: isSelected,
                ),
                SizedBox(height: context.heightByContext(8)),
                Text(
                  ratio.label,
                  style: AppTextStyle.base(
                    12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.postEditorOnSurface : AppColors.postEditorOnSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AspectRatioFrame extends StatelessWidget {
  const _AspectRatioFrame({
    required this.ratio,
    required this.selected,
  });

  final double ratio;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final boxHeight = context.heightByContext(AppImageEditorPage._figmaAspectFrameHeight);
    final maxWidth = context.widthByContext(52);

    late final double frameWidth;
    late final double frameHeight;

    if (maxWidth / boxHeight > ratio) {
      frameHeight = boxHeight;
      frameWidth = frameHeight * ratio;
    } else {
      frameWidth = maxWidth;
      frameHeight = frameWidth / ratio;
    }

    return SizedBox(
      height: boxHeight,
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          width: frameWidth,
          height: frameHeight,
          decoration: BoxDecoration(
            color: selected ? AppColors.postEditorSliderOverlay : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.postEditorCta : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
