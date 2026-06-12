import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/core/shared/image_select/models/app_image_selector_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

export 'package:clover/core/shared/image_select/models/app_image_selector_result.dart';

/// Переиспользуемый экран выбора фото из галереи (только изображения, без видео).
///
/// Верхнее превью всегда отображается в формате 4:3.
class AppImageSelectorPage extends StatefulWidget {
  const AppImageSelectorPage({
    super.key,
    this.title = 'Выбор фото',
    this.confirmLabel = 'Далее',
    this.maxGalleryItems = 100,
    this.maxSelectionCount = 15,
    this.onClose,
    this.onConfirmed,
  });

  final String title;
  final String confirmLabel;
  final int maxGalleryItems;
  final int maxSelectionCount;
  final VoidCallback? onClose;
  final ValueChanged<AppImageSelectorResult>? onConfirmed;

  static const double _figmaAppBarTitleFont = 17;
  static const double _figmaSectionHPadding = 16;
  static const double _figmaSectionVPadding = 12;
  static const double _figmaAlbumTitleFont = 15;
  static const double _figmaAlbumChevronSize = 20;
  static const double _figmaGridCrossCount = 4;
  static const double _figmaGridSpacing = 2;
  static const double _figmaCloseIconSize = 24;
  static const double _figmaSelectedOverlayAlpha = 0.28;
  static final double _figmaPreviewAspectRatio = PostMediaLayout.selectorPreviewAspectRatio;
  @override
  State<AppImageSelectorPage> createState() => _AppImageSelectorPageState();
}

class _AppImageSelectorPageState extends State<AppImageSelectorPage> {
  List<AssetPathEntity> _albums = [];
  List<AssetEntity> _mediaList = [];
  final List<AssetEntity> _selectedAssets = [];
  AssetPathEntity? _selectedAlbum;
  AssetEntity? _previewAsset;
  bool _isLoading = true;
  bool _isAlbumLoading = false;

  @override
  void initState() {
    super.initState();
    _initGallery();
  }

  Future<void> _initGallery() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      if (!permission.isAuth) {
        setState(() => _isLoading = false);
        return;
      }

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (!mounted) return;

      setState(() {
        _albums = albums;
        _selectedAlbum = albums.isNotEmpty ? albums.first : null;
        _isLoading = false;
      });

      if (_selectedAlbum != null) {
        await _loadAlbumAssets(_selectedAlbum!);
      }
    } catch (error, stackTrace) {
      debugPrint('AppImageSelectorPage: failed to init gallery: $error\n$stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAlbumAssets(AssetPathEntity album) async {
    setState(() => _isAlbumLoading = true);

    try {
      final end = widget.maxGalleryItems.clamp(1, 500);
      final media = await album.getAssetListRange(start: 0, end: end);
      final images = media.where((asset) => asset.type == AssetType.image).toList();

      if (!mounted) return;

      setState(() {
        _mediaList = images;
        _isAlbumLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('AppImageSelectorPage: failed to load album assets: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _mediaList = [];
          _isAlbumLoading = false;
        });
      }
    }
  }

  void _handleAlbumSelected(AssetPathEntity album) {
    if (identical(album, _selectedAlbum)) return;

    setState(() => _selectedAlbum = album);
    _loadAlbumAssets(album);
  }

  int? _selectionOrder(AssetEntity asset) {
    final index = _selectedAssets.indexWhere((item) => item.id == asset.id);
    if (index < 0) return null;
    return index + 1;
  }

  void _toggleSelection(AssetEntity asset) {
    final index = _selectedAssets.indexWhere((item) => item.id == asset.id);

    if (index >= 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedAssets.removeAt(index);
        if (_previewAsset?.id == asset.id) {
          _previewAsset = _selectedAssets.isEmpty ? null : _selectedAssets.last;
        }
      });
      return;
    }

    if (_selectedAssets.length >= widget.maxSelectionCount) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Можно выбрать не больше ${widget.maxSelectionCount} фото'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _selectedAssets.add(asset);
      _previewAsset = asset;
    });
  }

  String _albumDisplayName(AssetPathEntity album) {
    if (album.isAll) return 'Последние';

    final name = album.name.trim();
    if (name.isEmpty) return 'Альбом';

    return switch (name.toLowerCase()) {
      'recents' || 'recent' => 'Последние',
      'favorites' || 'favourites' || 'favorite' => 'Избранное',
      'screenshots' => 'Снимки экрана',
      'selfies' => 'Селфи',
      'live photos' => 'Live Photos',
      'panoramas' => 'Панорамы',
      'downloads' => 'Загрузки',
      _ => name,
    };
  }

  IconData _albumIcon(AssetPathEntity album) {
    final normalized = album.name.trim().toLowerCase();

    if (album.isAll || normalized == 'recents' || normalized == 'recent') {
      return Icons.access_time_rounded;
    }
    if (normalized.contains('favorite') || normalized.contains('favour')) {
      return Icons.favorite_border_rounded;
    }
    if (normalized.contains('screenshot')) {
      return Icons.screenshot_monitor_outlined;
    }
    if (normalized.contains('selfie')) {
      return Icons.face_retouching_natural_outlined;
    }

    return Icons.folder_outlined;
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _handleConfirm() {
    if (_selectedAssets.isEmpty) return;

    widget.onConfirmed?.call(AppImageSelectorResult(assets: List.unmodifiable(_selectedAssets)));
  }

  String get _titleWithCount => '${widget.title} (${_selectedAssets.length}/${widget.maxSelectionCount})';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, size: context.widthByContext(AppImageSelectorPage._figmaCloseIconSize)),
          color: AppColors.textColor,
          onPressed: _handleClose,
        ),
        title: Text(
          _titleWithCount,
          style: AppTextStyle.base(
            AppImageSelectorPage._figmaAppBarTitleFont,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
        ),
        actions: [
          AppTextButton(text: widget.confirmLabel, onTap: _selectedAssets.isEmpty ? null : _handleConfirm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _albums.isEmpty
          ? Center(
              child: Text(
                'Нет доступных изображений',
                style: AppTextStyle.base(15, color: AppColors.subTextColor),
              ),
            )
          : Column(
              children: [
                _PreviewArea(asset: _previewAsset),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.widthByContext(AppImageSelectorPage._figmaSectionHPadding),
                    vertical: context.heightByContext(AppImageSelectorPage._figmaSectionVPadding),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _selectedAlbum == null
                        ? const SizedBox.shrink()
                        : AppMiniMenu<AssetPathEntity>(
                            menuTooltip: 'Выбор альбома',
                            items: _albums
                                .map(
                                  (album) => AppMiniMenuItem(
                                    value: album,
                                    title: _albumDisplayName(album),
                                    icon: _albumIcon(album),
                                  ),
                                )
                                .toList(),
                            onSelected: _handleAlbumSelected,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _albumDisplayName(_selectedAlbum!),
                                  style: AppTextStyle.base(
                                    AppImageSelectorPage._figmaAlbumTitleFont,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                SizedBox(width: context.widthByContext(4)),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: context.widthByContext(AppImageSelectorPage._figmaAlbumChevronSize),
                                  color: AppColors.textColor,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: _isAlbumLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _mediaList.isEmpty
                      ? Center(
                          child: Text(
                            'В этом альбоме нет фото',
                            style: AppTextStyle.base(15, color: AppColors.subTextColor),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: AppImageSelectorPage._figmaGridCrossCount.toInt(),
                            crossAxisSpacing: context.widthByContext(AppImageSelectorPage._figmaGridSpacing),
                            mainAxisSpacing: context.widthByContext(AppImageSelectorPage._figmaGridSpacing),
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            final asset = _mediaList[index];
                            final order = _selectionOrder(asset);
                            final isSelected = order != null;

                            return GestureDetector(
                              onTap: () => _toggleSelection(asset),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AssetEntityImage(
                                    asset,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize(200, 200),
                                    fit: BoxFit.cover,
                                  ),
                                  if (isSelected)
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: AppImageSelectorPage._figmaSelectedOverlayAlpha,
                                        ),
                                        border: Border.all(color: AppColors.primary, width: 2),
                                      ),
                                    ),
                                  if (order != null)
                                    Positioned(top: 6, right: 6, child: _SelectionBadge(order: order)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    const size = 22.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Text(
        '$order',
        style: AppTextStyle.base(12, fontWeight: FontWeight.w800, color: AppColors.textInverse),
      ),
    );
  }
}

class _PreviewArea extends StatelessWidget {
  const _PreviewArea({required this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSoft,
      child: AspectRatio(
        aspectRatio: AppImageSelectorPage._figmaPreviewAspectRatio,
        child: asset == null
            ? Center(
                child: Text('Выберите фото', style: AppTextStyle.base(15, color: AppColors.subTextColor)),
              )
            : AssetEntityImage(
                asset!,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize(1200, 1200),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
