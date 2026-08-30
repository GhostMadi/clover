import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:flutter/material.dart';

/// Шиммер блока маркера под подписью поста (адрес, время, теги).
class PostMarkerDetailsShimmer extends StatelessWidget {
  const PostMarkerDetailsShimmer({super.key});

  static Widget _box(BuildContext context, {required double height, double? width, double radius = 8}) {
    final colors = AppColors.of(context);
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
    final colors = AppColors.of(context);
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(context, height: 28, width: 28, radius: 14),
              SizedBox(width: 10),
              Expanded(child: _box(context, height: 12)),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.borderSoft, width: 3)),
            ),
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(context, height: 10, width: 100, radius: 4),
                const SizedBox(height: 8),
                _box(context, height: 16, width: double.infinity),
                const SizedBox(height: 6),
                _box(context, height: 12, width: 180),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.borderSoft, width: 3)),
            ),
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(context, height: 10, width: 88, radius: 4),
                      const SizedBox(height: 8),
                      _box(context, height: 14, width: 160),
                    ],
                  ),
                ),
                _box(context, height: 22, width: 64, radius: 10),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _box(context, height: 26, width: 72, radius: 8),
              _box(context, height: 26, width: 88, radius: 8),
              _box(context, height: 26, width: 64, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
