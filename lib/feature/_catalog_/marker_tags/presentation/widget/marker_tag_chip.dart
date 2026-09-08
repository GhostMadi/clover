import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:flutter/material.dart';

/// Чип тега: силовые теги красятся цветом **сервиса** ([MarkerTagModel.serviceKind]).
class MarkerTagChip extends StatelessWidget {
  const MarkerTagChip({
    super.key,
    required this.tag,
    this.hashPrefix = true,
  });

  final MarkerTagModel tag;
  final bool hashPrefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = tag.serviceKind;
    final accent = service == null ? null : colors.serviceAccent(service);

    final background = accent?.soft ?? colors.primary.withValues(alpha: 0.06);
    final foreground = accent?.icon ?? colors.primary;

    final label = hashPrefix ? '#${tag.labelRu.toLowerCase()}' : tag.labelRu;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: accent == null
            ? null
            : Border.all(color: accent.ctaBorder.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: AppTextStyle.base(11, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}
