import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

extension EditProfileBannerRouterExtension on StackRouter {
  Future<void> pushEditProfileBannerEditor() => push(const EditProfileBannerEditorRoute());

  Future<void> pushEditProfileBannerConfirm() => push(const EditProfileBannerConfirmRoute());

  void closeEditProfileBannerFlow() {
    popUntil((route) => route.settings.name == EditProfileRoute.name);
  }
}
