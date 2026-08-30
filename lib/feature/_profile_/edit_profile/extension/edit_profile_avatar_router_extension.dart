import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

extension EditProfileAvatarRouterExtension on StackRouter {
  Future<void> pushEditProfileAvatarEditor() => push(const EditProfileAvatarEditorRoute());

  Future<void> pushEditProfileAvatarConfirm() => push(const EditProfileAvatarConfirmRoute());

  void closeEditProfileAvatarFlow() {
    popUntil((route) => route.settings.name == EditProfileRoute.name);
  }
}
