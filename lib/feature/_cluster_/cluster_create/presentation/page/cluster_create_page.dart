import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/cluster_create/cluster_create_flow.dart';
import 'package:clover/feature/cluster_create/extension/cluster_create_router_extension.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ClusterCreatePage extends StatelessWidget {
  const ClusterCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = ClusterCreateFlow.instance;

    return AppImageSelectorPage(
      title: 'Новый кластер',
      confirmLabel: 'Далее',
      maxSelectionCount: ClusterCreateFlow.maxPhotos,
      onClose: () {
        flow.reset();
        context.router.maybePop();
      },
      onConfirmed: (result) {
        flow.saveSelection(result.assets);
        context.router.pushClusterCreateEditor();
      },
    );
  }
}
