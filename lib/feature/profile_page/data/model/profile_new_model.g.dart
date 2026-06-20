// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_new_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileNewModel _$ProfileNewModelFromJson(
  Map<String, dynamic> json,
) => _ProfileNewModel(
  id: json['id'] as String,
  email: json['email'] as String?,
  fullName: json['full_name'] as String?,
  username: json['username'] as String?,
  categoryCodeRaw: json['category_code'] as String?,
  cityCodeRaw: json['city_code'] as String?,
  countryCodeRaw: json['country_code'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  backgroundUrl: json['background_url'] as String?,
  bio: json['bio'] as String?,
  phone: json['phone'] as String?,
  followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
  followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
  clusterCount: (json['cluster_count'] as num?)?.toInt() ?? 0,
  postCount: (json['post_count'] as num?)?.toInt() ?? 0,
  usernameChangeCount: (json['username_change_count'] as num?)?.toInt() ?? 0,
  usernameNextChangeAllowedAt: json['username_next_change_allowed_at'] == null
      ? null
      : DateTime.parse(json['username_next_change_allowed_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  hiringEnabled: json['hiring_enabled'] as bool? ?? false,
  openForMemberships: json['open_for_memberships'] as bool? ?? false,
  hasFilters: json['has_filters'] as bool? ?? false,
  tagLinkId: json['tag_link_id'] as String?,
  tagIds:
      (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ProfileNewModelToJson(_ProfileNewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'username': instance.username,
      'category_code': instance.categoryCodeRaw,
      'city_code': instance.cityCodeRaw,
      'country_code': instance.countryCodeRaw,
      'avatar_url': instance.avatarUrl,
      'background_url': instance.backgroundUrl,
      'bio': instance.bio,
      'phone': instance.phone,
      'followers_count': instance.followersCount,
      'following_count': instance.followingCount,
      'cluster_count': instance.clusterCount,
      'post_count': instance.postCount,
      'username_change_count': instance.usernameChangeCount,
      'username_next_change_allowed_at': instance.usernameNextChangeAllowedAt
          ?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'hiring_enabled': instance.hiringEnabled,
      'open_for_memberships': instance.openForMemberships,
      'has_filters': instance.hasFilters,
      'tag_link_id': instance.tagLinkId,
      'tag_ids': instance.tagIds,
    };
