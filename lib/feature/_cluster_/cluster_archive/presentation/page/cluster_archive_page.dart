import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_cluster_/shared/presentation/widget/archive_cluster_grid_shimmer.dart';
import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cubit/archived_clusters_cubit.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_card.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class ClusterArchivePage extends StatefulWidget {
  const ClusterArchivePage({super.key});

  @override
  State<ClusterArchivePage> createState() => _ClusterArchivePageState();
}

class _ClusterArchivePageState extends State<ClusterArchivePage> {
  late final ArchivedClustersCubit _cubit;
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  static const double _figmaGap = 12;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ArchivedClustersCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _cubit.load(uid);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = _uid?.trim();
    if (uid == null || uid.isEmpty) return;
    await _cubit.load(uid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Архив кластеров',
        body: AppRefresh(
          onRefresh: _refresh,
          child: BlocBuilder<ArchivedClustersCubit, ArchivedClustersState>(
            builder: (context, state) {
              return state.when(
                initial: () => const ArchiveClusterGridShimmer(),
                loading: () => const ArchiveClusterGridShimmer(),
                loaded: (items) {
                  if (items.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: SettingsScreenShell.scrollBottomGap(context)),
                      child: SizedBox(
                        height: context.heightByContext(240),
                        child: Center(
                          child: Text(
                            'Архив кластеров пуст',
                            style: TextStyle(color: AppColors.subTextColor, fontSize: context.heightByContext(14)),
                          ),
                        ),
                      ),
                    );
                  }

                  final gap = context.widthByContext(_figmaGap);
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final cluster in items)
                          _ArchivedClusterCard(
                            cluster: cluster,
                            onChanged: _refresh,
                          ),
                      ],
                    ),
                  );
                },
                error: (message) => _ArchiveError(message: message, onRetry: _refresh),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArchivedClusterCard extends StatelessWidget {
  const _ArchivedClusterCard({required this.cluster, required this.onChanged});

  final ClusterModel cluster;
  final Future<void> Function() onChanged;

  static final _menuItems = [
    AppMiniMenuItem(value: 'unarchive', title: 'Разархивировать', icon: Icons.unarchive_outlined),
    AppMiniMenuItem(
      value: 'delete',
      title: 'Удалить',
      icon: Icons.delete_outline,
      titleColor: AppColors.error,
      iconColor: AppColors.error,
    ),
  ];

  Future<void> _unarchive(BuildContext context, ArchivedClustersCubit cubit) async {
    final ok = await AppDialog.showConfirm(
      context: context,
      title: 'Разархивировать кластер?',
      message: 'Он снова появится в профиле.',
      confirmLabel: 'Разархивировать',
      upperCaseTitle: false,
    );
    if (ok != true || !context.mounted) return;

    try {
      await cubit.unarchive(cluster.id);
      clusterListRefreshTick.value++;
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Кластер разархивирован', kind: AppSnackBarKind.success);
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _delete(BuildContext context, ArchivedClustersCubit cubit) async {
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
      await cubit.delete(cluster.id);
      clusterListRefreshTick.value++;
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Кластер удалён', kind: AppSnackBarKind.success);
      await onChanged();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  void _onMenu(BuildContext context, ArchivedClustersCubit cubit, String action) {
    switch (action) {
      case 'unarchive':
        unawaited(_unarchive(context, cubit));
      case 'delete':
        unawaited(_delete(context, cubit));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArchivedClustersCubit>();
    return ClusterCard(
      title: cluster.title,
      subtitle: cluster.subtitle,
      coverUrl: cluster.coverUrl,
      countLabel: cluster.postsCountLabel,
      menuItems: _menuItems,
      onMenuSelected: (v) => _onMenu(context, cubit, v),
    );
  }
}

class _ArchiveError extends StatelessWidget {
  const _ArchiveError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.subTextColor)),
          const SizedBox(height: 12),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
