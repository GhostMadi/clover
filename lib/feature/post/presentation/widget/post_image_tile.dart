import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:clover/core/storage/app_progressive_network_image.dart';
import 'package:flutter/material.dart';

/// Плитка изображения поста: progressive remote + placeholder.
class PostImageTile extends StatelessWidget {
  const PostImageTile({
    super.key,
    required this.imageUrl,
    this.blurHash,
    this.memCacheWidth,
    this.borderRadius = 12,
  });

  final String? imageUrl;
  final String? blurHash;
  final int? memCacheWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: const ColoredBox(
          color: AppColors.surfaceSoft,
          child: Center(
            child: Icon(Icons.image_outlined, color: AppColors.iconMuted, size: 28),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AppProgressiveNetworkImage(
        imageUrl: url,
        blurHash: blurHash,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(borderRadius),
        fadeInDuration: const Duration(milliseconds: 120),
      ),
    );
  }
}

/// Placeholder пока нет url (shimmer).
class PostImagePlaceholder extends StatelessWidget {
  const PostImagePlaceholder({super.key, this.borderRadius = 12});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AppShimmer(
        child: const ColoredBox(color: AppColors.white),
      ),
    );
  }
}
