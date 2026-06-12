import 'dart:io';

import 'package:clover/core/shared/image_select/app_image_crop_math.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:flutter/material.dart';

/// Статичное превью отредактированного фото (формат, crop, фильтры).
class AppImageEditPreview extends StatelessWidget {
  const AppImageEditPreview({
    super.key,
    required this.imageFile,
    required this.settings,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.borderRadius = 0,
    this.backgroundColor,
  });

  final File imageFile;
  final AppImageEditSettings settings;
  final int imageWidth;
  final int imageHeight;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: settings.aspectRatio.ratio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          var width = imageWidth.toDouble();
          var height = imageHeight.toDouble();
          if (width <= 0 || height <= 0) {
            width = viewport.width;
            height = viewport.height;
          }

          final clamped = AppImageCropMath.clampTransform(
            userScale: settings.cropScale,
            offset: settings.cropOffset,
            viewportWidth: viewport.width,
            viewportHeight: viewport.height,
            imageWidth: width,
            imageHeight: height,
          );

          final render = AppImageCropMath.renderSize(
            viewportWidth: viewport.width,
            viewportHeight: viewport.height,
            imageWidth: width,
            imageHeight: height,
            userScale: clamped.scale,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ColoredBox(
              color: backgroundColor ?? Colors.transparent,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: (viewport.width - render.width) / 2 + clamped.offset.dx,
                      top: (viewport.height - render.height) / 2 + clamped.offset.dy,
                      width: render.width,
                      height: render.height,
                      child: ColorFiltered(
                        colorFilter: settings.colorFilter,
                        child: Image.file(
                          imageFile,
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
            ),
          );
        },
      ),
    );
  }
}
