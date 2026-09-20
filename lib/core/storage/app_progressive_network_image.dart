import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Обертка над cached_network_image / Image.asset с опциональным blurhash placeholder.
class AppProgressiveNetworkImage extends StatelessWidget {
  const AppProgressiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.blurHash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.fadeInDuration = Duration.zero,
  });

  final String imageUrl;
  final String? blurHash;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  final Duration fadeInDuration;

  static bool isAssetPath(String url) {
    final t = url.trim();
    return t.startsWith('assets/') || t.startsWith('asset:');
  }

  /// Убирает `asset:` и маркер `__ar-WxH` из пути для [Image.asset].
  static String normalizeAssetPath(String url) {
    var t = url.trim();
    if (t.startsWith('asset:')) t = t.substring('asset:'.length);
    t = t.replaceAll(RegExp(r'__ar-\d+x\d+', caseSensitive: false), '');
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceSoft;
    final url = imageUrl.trim();

    Widget child;
    if (url.isEmpty) {
      child = DecoratedBox(decoration: BoxDecoration(color: bg));
    } else if (isAssetPath(url)) {
      child = Image.asset(
        normalizeAssetPath(url),
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(color: bg)),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 80),
        useOldImageOnUrlChange: true,
        imageBuilder: (context, provider) =>
            Image(image: provider, fit: fit, gaplessPlayback: true, filterQuality: FilterQuality.low),
        placeholder: (_, __) {
          return DecoratedBox(decoration: BoxDecoration(color: bg));
        },
        errorWidget: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(color: bg)),
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    return SizedBox.expand(child: child);
  }
}
