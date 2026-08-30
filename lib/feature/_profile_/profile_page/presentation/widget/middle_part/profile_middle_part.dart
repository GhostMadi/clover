import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_card.dart' show clusterStripHeight;
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_list.dart';
import 'package:flutter/material.dart';

/// Средняя часть профиля: полоса коллекций.
class ProfileMiddlePart extends StatelessWidget {
  const ProfileMiddlePart({
    super.key,
    this.ownerId,
    this.selectedClusterId,
    this.onClusterTap,
    this.readOnly = false,
  });

  /// `null` — скелетон.
  final String? ownerId;
  final String? selectedClusterId;
  final ValueChanged<ClusterModel>? onClusterTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final id = ownerId?.trim();
    if (id == null || id.isEmpty) {
      return SizedBox(height: clusterStripHeight(context));
    }
    return ClusterList(
      ownerId: id,
      selectedClusterId: selectedClusterId,
      onClusterTap: onClusterTap,
      readOnly: readOnly,
    );
  }
}
