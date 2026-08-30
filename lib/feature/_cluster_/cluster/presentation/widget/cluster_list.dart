import 'dart:async';
import 'package:clover/core/resources/app_icons.dart';

import 'package:clover/core/dependencies/get_it.dart' show sl;
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/data/repository/cluster_repository.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_card.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_shimmer.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Горизонтальный список кластеров владельца.
class ClusterList extends StatefulWidget {
  const ClusterList({
    super.key,
    required this.ownerId,
    this.selectedClusterId,
    this.onClusterTap,
    this.leading,
    this.readOnly = false,
  });

  final String ownerId;
  final String? selectedClusterId;
  final ValueChanged<ClusterModel>? onClusterTap;
  final Widget? leading;
  final bool readOnly;

  @override
  State<ClusterList> createState() => _ClusterListState();
}

class _ClusterListState extends State<ClusterList> {
  static const double _figmaListPaddingH = 16;
  static const double _figmaListPaddingV = 4;
  static const double _figmaListPaddingBottom = 8;
  static const double _figmaItemGap = 12;

  int _lastRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _lastRefreshTick = clusterListRefreshTick.value;
    clusterListRefreshTick.addListener(_onGlobalRefreshTick);
  }

  @override
  void didUpdateWidget(covariant ClusterList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      context.read<ClustersListCubit>().load(widget.ownerId);
    }
  }

  @override
  void dispose() {
    clusterListRefreshTick.removeListener(_onGlobalRefreshTick);
    super.dispose();
  }

  void _onGlobalRefreshTick() {
    final now = clusterListRefreshTick.value;
    if (now == _lastRefreshTick) return;
    _lastRefreshTick = now;
    if (!mounted) return;
    context.read<ClustersListCubit>().load(widget.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClustersListCubit, ClustersListState>(
      buildWhen: (prev, next) => prev.runtimeType != next.runtimeType || prev != next,
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => Padding(
            padding: EdgeInsets.only(bottom: context.heightByContext(_figmaListPaddingBottom)),
            child: const ClusterShimmer(),
          ),
          loaded: (items) {
            if (widget.leading == null && items.isEmpty) {
              return const SizedBox.shrink();
            }
            final itemGap = context.widthByContext(_figmaItemGap);
            return Padding(
              padding: EdgeInsets.only(bottom: context.heightByContext(_figmaListPaddingBottom)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: EdgeInsets.fromLTRB(
                  context.widthByContext(_figmaListPaddingH),
                  context.heightByContext(_figmaListPaddingV),
                  context.widthByContext(_figmaListPaddingH),
                  context.heightByContext(_figmaListPaddingV),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.leading != null) ...[widget.leading!, SizedBox(width: itemGap)],
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) SizedBox(width: itemGap),
                      _ClusterListCard(
                        cluster: items[i],
                        isSelected: widget.selectedClusterId == items[i].id,
                        onTap: () => widget.onClusterTap?.call(items[i]),
                        readOnly: widget.readOnly,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ClusterListCard extends StatelessWidget {
  const _ClusterListCard({
    required this.cluster,
    required this.isSelected,
    this.onTap,
    this.readOnly = false,
  });

  final ClusterModel cluster;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool readOnly;

  static List<AppMiniMenuItem<String>> _menuItems(AppPalette colors) => [
    AppMiniMenuItem(value: 'archive', title: 'Архивировать', icon: AppIcons.archive.icon),
    AppMiniMenuItem(
      value: 'delete',
      title: 'Удалить',
      icon: AppIcons.delete.icon,
      titleColor: colors.error,
      iconColor: colors.error,
    ),
  ];

  Future<void> _delete(BuildContext context) async {
    final ok = await AppDialog.showConfirm(
      context: context,
      title: 'Удалить кластер?',
      message: 'Обложка тоже будет удалена.',
      confirmLabel: 'Удалить',
      confirmIsDestructive: true,
      upperCaseTitle: false,
    );
    if (ok != true || !context.mounted) return;

    try {
      await sl<ClusterRepository>().deleteCluster(clusterId: cluster.id);
      clusterListRefreshTick.value++;
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Кластер удалён', kind: AppSnackBarKind.success);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _archive(BuildContext context) async {
    final ok = await AppDialog.showConfirm(
      context: context,
      title: 'Архивировать кластер?',
      message: 'Он пропадёт из списка в профиле.',
      confirmLabel: 'Архивировать',
      upperCaseTitle: false,
    );
    if (ok != true || !context.mounted) return;

    try {
      await sl<ClusterRepository>().archiveCluster(clusterId: cluster.id);
      clusterListRefreshTick.value++;
      unawaited(sl<ProfileCubit>().refresh());
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Кластер архивирован', kind: AppSnackBarKind.success);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  void _onMenu(BuildContext context, String action) {
    switch (action) {
      case 'delete':
        unawaited(_delete(context));
      case 'archive':
        unawaited(_archive(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClusterCard(
      title: cluster.title,
      subtitle: cluster.subtitle,
      coverUrl: cluster.coverUrl,
      countLabel: cluster.postsCountLabel,
      isSelected: isSelected,
      onTap: onTap,
      menuItems: readOnly ? null : _menuItems(context.colors),
      onMenuSelected: readOnly ? null : (v) => _onMenu(context, v),
    );
  }
}
