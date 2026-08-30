import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/_post_/post/data/models/post_media_model.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_image_tile.dart';
import 'package:flutter/material.dart';

/// Галерея медиа поста: свайп между фото, высота кадра по формату каждого снимка.
class PostMediaGallery extends StatefulWidget {
  const PostMediaGallery({super.key, required this.media});

  final List<PostMediaModel> media;

  @override
  State<PostMediaGallery> createState() => _PostMediaGalleryState();
}

class _PostMediaGalleryState extends State<PostMediaGallery> {
  final _pageController = PageController();
  int _pageIndex = 0;

  @override
  void didUpdateWidget(covariant PostMediaGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.length != widget.media.length) {
      _pageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  PostAspectRatio _aspectAt(int index) {
    final media = widget.media;
    if (media.isEmpty) return PostAspectRatio.square1x1;
    return media[index.clamp(0, media.length - 1)].aspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }

        final media = widget.media;
        if (media.isEmpty) {
          final height = PostAspectRatio.square1x1.detailHeightForWidth(width, screenHeight);
          return SizedBox(width: width, height: height, child: const PostImagePlaceholder(borderRadius: 0));
        }

        final safeIndex = _pageIndex.clamp(0, media.length - 1);
        final frameHeight = _aspectAt(safeIndex).detailHeightForWidth(width, screenHeight);

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: frameHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: media.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final item = media[index];
                    return PostImageTile(
                      imageUrl: item.previewImageUrl,
                      blurHash: item.blurHash,
                      borderRadius: 0,
                    );
                  },
                ),
                if (media.length > 1) _PageDots(count: media.length, activeIndex: safeIndex),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == activeIndex;
          final dot = context.colors.textInverse;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              color: isActive ? dot : dot.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowDark.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
