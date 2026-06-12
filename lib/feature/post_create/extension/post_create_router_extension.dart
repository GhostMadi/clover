import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

extension PostCreateRouterExtension on StackRouter {
  Future<void> pushPostCreateEditor() => push(const PostCreateEditorRoute());

  Future<void> pushPostCreateCompose() => push(const PostCreateComposeRoute());

  void closePostCreateFlow() {
    popUntil((route) => route.settings.name == PostCreateRoute.name);
    maybePop();
  }
}
