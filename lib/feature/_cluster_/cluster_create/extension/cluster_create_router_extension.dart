import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

extension ClusterCreateRouterExtension on StackRouter {
  Future<void> pushClusterCreateEditor() => push(const ClusterCreateEditorRoute());

  Future<void> pushClusterCreateCompose() => push(const ClusterCreateComposeRoute());

  void closeClusterCreateFlow() {
    popUntil((route) => route.settings.name == ClusterCreateRoute.name);
    maybePop();
  }
}
