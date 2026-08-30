import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Шторка группы маркеров: сетка emoji-маркеров для выбора.
abstract final class MapMarkerGroupSheet {
  static Future<MapMarkerItem?> show(BuildContext context, {required List<MapMarkerItem> markers}) {
    return AppBottomSheet.show<MapMarkerItem>(
      context: context,
      title: 'События',
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 8,
      content: _MapMarkerGroupGrid(markers: markers),
    );
  }
}

class _MapMarkerGroupGrid extends StatelessWidget {
  const _MapMarkerGroupGrid({required this.markers});

  final List<MapMarkerItem> markers;

  static const _columns = 3;
  static const _spacing = 14.0;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
        childAspectRatio: 0.82,
      ),
      itemCount: markers.length,
      itemBuilder: (context, index) {
        final marker = markers[index];
        return _GridMarkerTile(
          emoji: _emojiFor(marker.textEmoji),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, marker);
          },
        );
      },
    );
  }

  static String _emojiFor(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '📍' : trimmed;
  }
}

class _GridMarkerTile extends StatelessWidget {
  const _GridMarkerTile({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final circleSize = constraints.maxWidth.clamp(72.0, 96.0);
            final emojiSize = circleSize * 0.72;

            return Center(
              child: SizedBox(
                width: circleSize,
                height: circleSize + emojiSize * 0.18,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.shadowDark.withValues(alpha: 0.14),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(width: circleSize, height: circleSize),
                      ),
                    ),
                    Positioned(
                      bottom: circleSize * 0.2,
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: emojiSize, height: 1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
