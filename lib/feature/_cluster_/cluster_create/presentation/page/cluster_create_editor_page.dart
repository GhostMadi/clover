import 'package:auto_route/auto_route.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/image_select/app_image_editor_page.dart';
import 'package:clover/feature/cluster_create/cluster_create_flow.dart';
import 'package:clover/feature/cluster_create/extension/cluster_create_router_extension.dart';
import 'package:clover/feature/cluster_create/presentation/widget/cluster_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ClusterCreateEditorPage extends StatelessWidget {
  const ClusterCreateEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = ClusterCreateFlow.instance;
    final draft = flow.draft;

    return ClusterCreateStepGuard(
      canShow: draft.canOpenEditor,
      child: AppImageEditorPage(
        assets: draft.selectedAssets,
        title: 'Обложка кластера',
        lockedAspectRatio: PostAspectRatio.square1x1,
        onClose: () => context.router.maybePop(),
        onDone: (results) {
          flow.saveEditedMedia(results);
          context.router.pushClusterCreateCompose();
        },
      ),
    );
  }
}
