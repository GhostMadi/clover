import 'package:clover/feature/cluster/presentation/widget/cluster_card.dart' show clusterStripHeight;
import 'package:clover/feature/cluster/presentation/widget/cluster_list.dart';
import 'package:flutter/material.dart';

/// Средняя часть профиля: полоса коллекций.
class ProfileMiddlePart extends StatelessWidget {
  const ProfileMiddlePart({super.key, this.ownerId});

  /// `null` — скелетон.
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    final id = ownerId?.trim();
    if (id == null || id.isEmpty) {
      return SizedBox(height: clusterStripHeight(context));
    }
    return ClusterList(ownerId: id);
  }
}
