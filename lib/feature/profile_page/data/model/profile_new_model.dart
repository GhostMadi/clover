import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:clover/core/catalog_sync/models/sync_meta.dart';
import 'package:clover/feature/city/data/models/city_code.dart';
import 'package:clover/feature/countries/data/models/country_code.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_key.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_categories/data/models/profile_category_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_new_model.freezed.dart';
part 'profile_new_model.g.dart';

/// Строка `public.profiles` (ответ PostgREST / Supabase).
@freezed
abstract class ProfileNewModel with _$ProfileNewModel {
  const ProfileNewModel._();

  const factory ProfileNewModel({
    required String id,
    String? email,
    @JsonKey(name: 'full_name') String? fullName,
    String? username,
    @JsonKey(name: 'category_code') String? categoryCodeRaw,
    @JsonKey(name: 'city_code') String? cityCodeRaw,
    @JsonKey(name: 'country_code') String? countryCodeRaw,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'background_url') String? backgroundUrl,
    String? bio,
    String? phone,
    @JsonKey(name: 'followers_count') @Default(0) int followersCount,
    @JsonKey(name: 'following_count') @Default(0) int followingCount,
    @JsonKey(name: 'cluster_count') @Default(0) int clusterCount,
    @JsonKey(name: 'post_count') @Default(0) int postCount,
    @JsonKey(name: 'username_change_count') @Default(0) int usernameChangeCount,
    @JsonKey(name: 'username_next_change_allowed_at') DateTime? usernameNextChangeAllowedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'has_filters') @Default(false) bool hasFilters,
    @JsonKey(name: 'bonus_program_status')
    @Default(BonusProgramStatus.inactive)
    BonusProgramStatus bonusProgramStatus,
    @JsonKey(name: 'tag_link_id') String? tagLinkId,
    @JsonKey(name: 'tag_ids') @Default([]) List<String> tagIds,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default([]) List<MarkerTagModel> tags,
    @JsonKey(includeFromJson: false, includeToJson: false) SyncMeta? syncMeta,
  }) = _ProfileNewModel;

  factory ProfileNewModel.fromJson(Map<String, dynamic> json) => _$ProfileNewModelFromJson(json);

  /// Категория из справочника.
  ProfileCategoryCode? get categoryCode => ProfileCategoryCode.tryParse(categoryCodeRaw);

  /// Страна как в `public.countries.code`.
  CountryCode? get countryCode => CountryCode.tryParse(countryCodeRaw);

  /// Город, если slug известен enum'у [CityCode].
  CityCode? get cityCode {
    final slug = cityCodeRaw?.trim();
    final country = countryCode;
    if (slug == null || slug.isEmpty || country == null) return null;
    return CityCode.tryParse(countryCode: country.code, cityCode: slug);
  }

  /// Сырой `city_code`, если enum не распознал slug.
  String? get citySlug {
    final slug = cityCodeRaw?.trim();
    if (slug == null || slug.isEmpty || cityCode != null) return null;
    return slug;
  }

  /// Подпись города для UI.
  String? get cityLabel => cityCode?.labelRu ?? citySlug;

  /// Подпись категории для UI.
  String? get categoryLabelRu => categoryCode?.labelRu;

  bool get isBonusProgramActive => bonusProgramStatus.isActive;

  /// «Страна,город» или одно из полей — для строки локации в хедере.
  String get locationLine {
    final city = cityLabel?.trim();
    final country = countryCode?.labelRu.trim();
    final hasCity = city != null && city.isNotEmpty;
    final hasCountry = country != null && country.isNotEmpty;

    if (hasCity && hasCountry) return '$country, $city';
    if (hasCity) return city;
    if (hasCountry) return country;
    return '';
  }

  /// Есть привязанный набор тегов (`profiles.tag_link_id`).
  bool get hasAccountTags => tagLinkId != null && tagLinkId!.trim().isNotEmpty;

  Set<String> get tagIdSet => tagIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

  bool hasAccountTag(MarkerTagKey key) => tags.any((tag) => tag.keyEnum == key);

  /// Включена запись на приём (`booking` в тегах аккаунта).
  bool get hasBookingTag => hasAccountTag(MarkerTagKey.booking);
}
