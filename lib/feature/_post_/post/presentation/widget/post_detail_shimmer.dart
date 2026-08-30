import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_marker_details_shimmer.dart';
import 'package:flutter/material.dart';

/// Шиммер экрана поста до появления [initialPost].
class PostDetailShimmer extends StatelessWidget {
  const PostDetailShimmer({super.key, this.showMarkerBlock = false});

  final bool showMarkerBlock;

  static Widget _box(BuildContext context, {required double height, double? width, double radius = 8}) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _box(context, height: 44, width: 44, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(child: _box(context, height: 14)),
                  const SizedBox(width: 12),
                  _box(context, height: 40, width: 112, radius: 14),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(color: colors.surfaceSoft),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(context, height: 14, width: 200),
                  const SizedBox(height: 10),
                  _box(context, height: 20, width: double.infinity),
                  const SizedBox(height: 8),
                  _box(context, height: 20, width: 240),
                  const SizedBox(height: 8),
                  _box(context, height: 14, width: double.infinity),
                  if (showMarkerBlock) ...[
                    const SizedBox(height: 24),
                    const PostMarkerDetailsShimmer(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
