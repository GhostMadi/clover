import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

extension MarkerCreateRouterExtension on StackRouter {
  Future<void> pushMarkerCreateEditor() => push(const MarkerCreateEditorRoute());

  Future<void> pushMarkerCreateCompose() => push(const MarkerCreateComposeRoute());

  void closeMarkerCreateFlow() {
    popUntil((route) => route.settings.name == MarkerCreateRoute.name);
    maybePop();
  }
}
