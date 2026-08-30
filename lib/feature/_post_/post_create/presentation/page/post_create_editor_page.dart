import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_editor_page.dart';
import 'package:clover/feature/post_create/extension/post_create_router_extension.dart';
import 'package:clover/feature/post_create/post_create_flow.dart';
import 'package:clover/feature/post_create/presentation/widget/post_create_step_guard.dart';
import 'package:flutter/material.dart';

@RoutePage()
class PostCreateEditorPage extends StatelessWidget {
  const PostCreateEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = PostCreateFlow.instance;
    final draft = flow.draft;

    return PostCreateStepGuard(
      canShow: draft.canOpenEditor,
      child: AppImageEditorPage(
        assets: draft.selectedAssets,
        onClose: () => context.router.maybePop(),
        onDone: (results) {
          flow.saveEditedMedia(results);
          context.router.pushPostCreateCompose();
        },
      ),
    );
  }
}
