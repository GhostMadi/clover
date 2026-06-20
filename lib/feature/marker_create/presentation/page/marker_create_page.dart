import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/marker_create/extension/marker_create_router_extension.dart';
import 'package:clover/feature/marker_create/marker_create_flow.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MarkerCreatePage extends StatelessWidget {
  const MarkerCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = MarkerCreateFlow.instance;

    return AppImageSelectorPage(
      title: 'Новый маркер',
      confirmLabel: 'Далее',
      maxSelectionCount: MarkerCreateFlow.maxPhotos,
      onClose: () {
        flow.reset();
        context.router.maybePop();
      },
      onConfirmed: (result) {
        flow.saveSelection(result.assets);
        context.router.pushMarkerCreateEditor();
      },
    );
  }
}
