import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_blurhash/flutter_blurhash.dart';
/// Обертка над cached_network_image с опциональным blurhash placeholder.
/// (LQIP ощущение "как Instagram" без кастомного загрузчика.)
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
    // В лентах/списках любые fade часто воспринимаются как "мигание" при pop/rebuild.
    // Поэтому по умолчанию отключаем fade, а где нужно — включаем явно.
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

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceSoft;
    final url = imageUrl.trim();
    final bh = blurHash?.trim();

    Widget child;
    if (url.isEmpty) {
      child = DecoratedBox(decoration: BoxDecoration(color: bg));
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 80),
        useOldImageOnUrlChange: true,
        imageBuilder: (context, provider) =>
            Image(image: provider, fit: fit, gaplessPlayback: true, filterQuality: FilterQuality.low),
        placeholder: (_, __) {
          // if (bh != null && bh.isNotEmpty) {
          //   return BlurHash(hash: bh, imageFit: fit, color: bg);
          // }
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
