import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_editor_page.dart';
import 'package:clover/feature/marker_create/extension/marker_create_router_extension.dart';
import 'package:clover/feature/marker_create/marker_create_flow.dart';
import 'package:clover/feature/marker_create/presentation/widget/marker_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MarkerCreateEditorPage extends StatelessWidget {
  const MarkerCreateEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = MarkerCreateFlow.instance;
    final draft = flow.draft;

    return MarkerCreateStepGuard(
      canShow: draft.canOpenEditor,
      child: AppImageEditorPage(
        assets: draft.selectedAssets,
        onClose: () => context.router.maybePop(),
        onDone: (results) {
          flow.saveEditedMedia(results);
          context.router.pushMarkerCreateCompose();
        },
      ),
    );
  }
}
