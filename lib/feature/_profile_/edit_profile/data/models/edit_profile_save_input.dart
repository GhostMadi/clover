import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';

class EditProfileSaveInput {
  const EditProfileSaveInput({
    required this.fullName,
    required this.bio,
    this.countryCode,
    this.cityCode,
    this.tagIds = const {},
    this.avatarPreview,
    this.backgroundPreview,
  });

  final String fullName;
  final String bio;
  final String? countryCode;
  final String? cityCode;
  final Set<String> tagIds;
  final AppImageEditorResult? avatarPreview;
  final AppImageEditorResult? backgroundPreview;
}
