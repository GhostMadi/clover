import 'dart:typed_data';

import 'package:clover/core/shared/image_select/app_image_edit_exporter.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/core/storage/r2_storage_service.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/repository/marker_tags_repository.dart';
import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_error.dart';
import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_save_input.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EditProfileRepository {
  Future<ProfileNewModel> updateProfile(EditProfileSaveInput input);

  Future<ProfileNewModel> updateUsername(String username);
}

@LazySingleton(as: EditProfileRepository)
class EditProfileRepositoryImpl implements EditProfileRepository {
  EditProfileRepositoryImpl(
    this._client,
    this._profileRepository,
    this._markerTagsRepository,
    this._r2,
  );

  final SupabaseClient _client;
  final ProfileNewRepository _profileRepository;
  final MarkerTagsRepository _markerTagsRepository;
  final R2StorageService _r2;

  static const _folderAvatars = 'avatars';
  static const _folderBackgrounds = 'profile_backgrounds';

  @override
  Future<ProfileNewModel> updateProfile(EditProfileSaveInput input) async {
    final uid = _requireUid();

    final payload = <String, dynamic>{
      'full_name': _nullableTrim(input.fullName),
      'bio': _nullableTrim(input.bio),
      'country_code': _nullableTrim(input.countryCode),
      'city_code': _nullableTrim(input.cityCode),
    };

    if (input.avatarPreview != null) {
      payload['avatar_url'] = await _uploadAvatar(preview: input.avatarPreview!);
    }
    if (input.backgroundPreview != null) {
      payload['background_url'] = await _uploadBackground(preview: input.backgroundPreview!);
    }

    try {
      await _client.from('profiles').update(payload).eq('id', uid);
      await _syncProfileTagLink(uid: uid, tagKeys: input.tagIds);
    } on PostgrestException catch (error) {
      throw EditProfileError.from(error);
    }

    return _requireCurrentProfile();
  }

  @override
  Future<ProfileNewModel> updateUsername(String username) async {
    final uid = _requireUid();
    final next = username.trim();
    if (next.isEmpty) {
      throw EditProfileError('Укажите никнейм');
    }

    try {
      await _client.from('profiles').update({'username': next}).eq('id', uid);
    } on PostgrestException catch (error) {
      throw EditProfileError.from(error);
    }

    return _requireCurrentProfile();
  }

  Future<void> _syncProfileTagLink({
    required String uid,
    required Set<String> tagKeys,
  }) async {
    final normalized = tagKeys.map((key) => key.trim()).where((key) => key.isNotEmpty).toSet();
    if (normalized.isEmpty) {
      await _clearProfileTagLink(uid);
      return;
    }

    final ids = await _markerTagsRepository.resolveTagIds(normalized);
    if (ids.isEmpty) {
      throw EditProfileError('Не удалось сохранить теги');
    }

    final sortedIds = ids..sort();

    final row = await _client.from('profiles').select('tag_link_id').eq('id', uid).maybeSingle();
    if (row == null) {
      throw EditProfileError('Профиль не найден');
    }

    final linkId = row['tag_link_id'] as String?;
    if (linkId == null || linkId.trim().isEmpty) {
      final inserted = await _client
          .from('profile_tag_links')
          .insert({'tag_ids': sortedIds})
          .select('id')
          .single();
      final newLinkId = inserted['id']?.toString().trim();
      if (newLinkId == null || newLinkId.isEmpty) {
        throw EditProfileError('Не удалось сохранить теги');
      }
      await _client.from('profiles').update({'tag_link_id': newLinkId}).eq('id', uid);
      return;
    }

    await _client.from('profile_tag_links').update({'tag_ids': sortedIds}).eq('id', linkId);
  }

  Future<void> _clearProfileTagLink(String uid) async {
    final row = await _client.from('profiles').select('tag_link_id').eq('id', uid).maybeSingle();
    if (row == null) return;

    final linkId = row['tag_link_id'] as String?;
    if (linkId == null || linkId.trim().isEmpty) return;

    // Удаляем link, пока profiles.tag_link_id ещё указывает на него (RLS delete_own).
    // FK on delete set null сбросит profiles.tag_link_id.
    await _client.from('profile_tag_links').delete().eq('id', linkId);
  }

  String _requireUid() {
    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      throw EditProfileError('Нет сессии: войдите в аккаунт');
    }
    return uid;
  }

  Future<ProfileNewModel> _requireCurrentProfile() async {
    final profile = await _profileRepository.getCurrent();
    if (profile == null) {
      throw EditProfileError('Профиль не найден');
    }
    return profile;
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<String> _uploadAvatar({
    required AppImageEditorResult preview,
  }) async {
    final bytes = await _exportPreviewBytes(preview);
    final compressed = await FlutterImageCompress.compressWithList(bytes, quality: 88);
    try {
      return await _r2.uploadBytes(
        compressed,
        fileName: 'avatar.jpg',
        folder: _folderAvatars,
        contentType: 'image/jpeg',
      );
    } catch (_) {
      throw EditProfileError('Не удалось загрузить аватар');
    }
  }

  Future<String> _uploadBackground({
    required AppImageEditorResult preview,
  }) async {
    final bytes = await _exportPreviewBytes(preview);
    final compressed = await FlutterImageCompress.compressWithList(bytes, quality: 88);
    try {
      return await _r2.uploadBytes(
        compressed,
        fileName: 'background.jpg',
        folder: _folderBackgrounds,
        contentType: 'image/jpeg',
      );
    } catch (_) {
      throw EditProfileError('Не удалось загрузить фон профиля');
    }
  }

  Future<Uint8List> _exportPreviewBytes(AppImageEditorResult preview) async {
    final sourceFile = preview.previewFile;
    if (sourceFile == null) {
      throw EditProfileError('Не удалось подготовить изображение');
    }

    return AppImageEditExporter.exportJpegBytes(
      sourceFile: sourceFile,
      settings: preview.settings,
      imageWidth: preview.asset.width,
      imageHeight: preview.asset.height,
    );
  }
}
