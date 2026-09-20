import 'dart:convert';

import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:flutter/services.dart';

/// Опубликованный план с сайта (мок JSON) → то, что мобилка только смотрит.
class VenuePublishedPlan {
  const VenuePublishedPlan({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.nodes,
    required this.version,
    required this.floorLabel,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<VenueMockPlanNode> nodes;
  final int version;
  final String floorLabel;

  double get aspectRatio => canvasWidth / canvasHeight;
}

abstract final class VenuePublishedPlanLoader {
  static const cafeAsset = 'assets/mocks/venue_plan_cafe.json';

  static Future<VenuePublishedPlan?> loadCafe() async {
    final raw = await rootBundle.loadString(cafeAsset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return fromJson(map);
  }

  static VenuePublishedPlan fromJson(Map<String, dynamic> root) {
    final plan = root['plan'] as Map<String, dynamic>;
    final canvas = plan['canvas'] as Map<String, dynamic>;
    final width = (canvas['width'] as num).toDouble();
    final height = (canvas['height'] as num).toDouble();

    final inventory = <String, VenueMockBookableState>{};
    for (final row in (root['inventory'] as List<dynamic>? ?? const [])) {
      final m = row as Map<String, dynamic>;
      final id = m['bookable_id'] as String?;
      if (id == null) continue;
      inventory[id] = switch (m['state'] as String?) {
        'held' => VenueMockBookableState.held,
        'taken' => VenueMockBookableState.taken,
        _ => VenueMockBookableState.free,
      };
    }

    final nodes = <VenueMockPlanNode>[];
    for (final rawNode in (plan['nodes'] as List<dynamic>? ?? const [])) {
      final n = rawNode as Map<String, dynamic>;
      final kind = n['kind'] as String? ?? 'rect';
      // path без frame — пропуск в мок-вьюере (стены позже)
      if (kind == 'path') continue;

      final frame = n['frame'] as Map<String, dynamic>?;
      if (frame == null) continue;

      final bookableId = n['bookable_id'] as String?;
      final role = n['role'] as String? ?? 'decor';
      final isDecor = role != 'bookable' || bookableId == null;
      final state = isDecor
          ? VenueMockBookableState.free
          : (inventory[bookableId] ?? VenueMockBookableState.free);

      nodes.add(
        VenueMockPlanNode(
          id: bookableId ?? (n['id'] as String? ?? 'node'),
          label: (n['label'] as String?) ?? '',
          left: (frame['x'] as num).toDouble() / width,
          top: (frame['y'] as num).toDouble() / height,
          width: (frame['w'] as num).toDouble() / width,
          height: (frame['h'] as num).toDouble() / height,
          state: state,
          isDecor: isDecor,
        ),
      );
    }

    return VenuePublishedPlan(
      canvasWidth: width,
      canvasHeight: height,
      nodes: nodes,
      version: (plan['version'] as num?)?.toInt() ?? 1,
      floorLabel: (plan['label'] as String?) ?? 'План',
    );
  }
}
