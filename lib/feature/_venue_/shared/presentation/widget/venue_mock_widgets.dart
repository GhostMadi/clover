import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

class VenueStateLegend extends StatelessWidget {
  const VenueStateLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final state in VenueMockBookableState.values)
          _LegendChip(
            label: VenueMockCatalog.stateLabel(state),
            soft: venueStateSoft(colors, state),
            ink: venueStateInk(colors, state),
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.soft,
    required this.ink,
  });

  final String label;
  final Color soft;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyle.base(12, fontWeight: FontWeight.w600, color: ink),
      ),
    );
  }
}

class VenueMockBanner extends StatelessWidget {
  const VenueMockBanner({super.key, this.text = 'Моки · без бэка'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = venueServiceAccent(context.colors);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTextStyle.base(13, fontWeight: FontWeight.w500, color: accent.onSoft),
      ),
    );
  }
}

class VenuePlanCanvas extends StatelessWidget {
  const VenuePlanCanvas({
    super.key,
    required this.nodes,
    this.onTapNode,
    this.selectedIds = const {},
    this.aspectRatio = 1.05,
  });

  final List<VenueMockPlanNode> nodes;
  final ValueChanged<VenueMockPlanNode>? onTapNode;
  final Set<String> selectedIds;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = venueServiceAccent(colors);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSoft),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                for (final node in nodes)
                  Positioned(
                    left: node.left * constraints.maxWidth,
                    top: node.top * constraints.maxHeight,
                    width: node.width * constraints.maxWidth,
                    height: node.height * constraints.maxHeight,
                    child: GestureDetector(
                      onTap: node.isDecor || onTapNode == null ? null : () => onTapNode!(node),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: node.isDecor
                              ? colors.surfaceMuted
                              : venueStateSoft(colors, node.state),
                          borderRadius: BorderRadius.circular(node.isDecor ? 12 : 14),
                          border: Border.all(
                            color: selectedIds.contains(node.id)
                                ? accent.cta
                                : (node.isDecor
                                    ? colors.border
                                    : venueStateInk(colors, node.state).withValues(alpha: 0.35)),
                            width: selectedIds.contains(node.id) ? 2.5 : 1,
                          ),
                        ),
                        child: Text(
                          node.label,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(
                            12,
                            fontWeight: FontWeight.w600,
                            color: node.isDecor
                                ? colors.subTextColor
                                : venueStateInk(colors, node.state),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
