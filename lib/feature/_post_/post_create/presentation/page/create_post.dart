import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_router_extension.dart';
import 'package:clover/feature/_post_/post_create/post_create_flow.dart';
import 'package:flutter/material.dart';

@RoutePage()
class PostCreatePage extends StatelessWidget {
  const PostCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = PostCreateFlow.instance;

    return AppImageSelectorPage(
      title: 'Новая публикация',
      confirmLabel: 'Далее',
      maxSelectionCount: PostCreateFlow.maxPhotos,
      onClose: () {
        flow.reset();
        context.router.maybePop();
      },
      onConfirmed: (result) {
        flow.saveSelection(result.assets);
        context.router.pushPostCreateEditor();
      },
    );
  }
}
