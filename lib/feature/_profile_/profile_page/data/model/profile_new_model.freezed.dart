// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_new_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileNewModel {

 String get id; String? get email;@JsonKey(name: 'full_name') String? get fullName; String? get username;@JsonKey(name: 'city_code') String? get cityCodeRaw;@JsonKey(name: 'country_code') String? get countryCodeRaw;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'background_url') String? get backgroundUrl; String? get bio; String? get phone;@JsonKey(name: 'followers_count') int get followersCount;@JsonKey(name: 'following_count') int get followingCount;@JsonKey(name: 'cluster_count') int get clusterCount;@JsonKey(name: 'post_count') int get postCount;@JsonKey(name: 'username_change_count') int get usernameChangeCount;@JsonKey(name: 'username_next_change_allowed_at') DateTime? get usernameNextChangeAllowedAt;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'has_filters') bool get hasFilters;@JsonKey(name: 'tag_link_id') String? get tagLinkId;@JsonKey(name: 'tag_ids') List<String> get tagIds;@JsonKey(includeFromJson: false, includeToJson: false) List<MarkerTagModel> get tags;
/// Create a copy of ProfileNewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileNewModelCopyWith<ProfileNewModel> get copyWith => _$ProfileNewModelCopyWithImpl<ProfileNewModel>(this as ProfileNewModel, _$identity);

  /// Serializes this ProfileNewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileNewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.username, username) || other.username == username)&&(identical(other.cityCodeRaw, cityCodeRaw) || other.cityCodeRaw == cityCodeRaw)&&(identical(other.countryCodeRaw, countryCodeRaw) || other.countryCodeRaw == countryCodeRaw)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.clusterCount, clusterCount) || other.clusterCount == clusterCount)&&(identical(other.postCount, postCount) || other.postCount == postCount)&&(identical(other.usernameChangeCount, usernameChangeCount) || other.usernameChangeCount == usernameChangeCount)&&(identical(other.usernameNextChangeAllowedAt, usernameNextChangeAllowedAt) || other.usernameNextChangeAllowedAt == usernameNextChangeAllowedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasFilters, hasFilters) || other.hasFilters == hasFilters)&&(identical(other.tagLinkId, tagLinkId) || other.tagLinkId == tagLinkId)&&const DeepCollectionEquality().equals(other.tagIds, tagIds)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,email,fullName,username,cityCodeRaw,countryCodeRaw,avatarUrl,backgroundUrl,bio,phone,followersCount,followingCount,clusterCount,postCount,usernameChangeCount,usernameNextChangeAllowedAt,createdAt,updatedAt,hasFilters,tagLinkId,const DeepCollectionEquality().hash(tagIds),const DeepCollectionEquality().hash(tags)]);

@override
String toString() {
  return 'ProfileNewModel(id: $id, email: $email, fullName: $fullName, username: $username, cityCodeRaw: $cityCodeRaw, countryCodeRaw: $countryCodeRaw, avatarUrl: $avatarUrl, backgroundUrl: $backgroundUrl, bio: $bio, phone: $phone, followersCount: $followersCount, followingCount: $followingCount, clusterCount: $clusterCount, postCount: $postCount, usernameChangeCount: $usernameChangeCount, usernameNextChangeAllowedAt: $usernameNextChangeAllowedAt, createdAt: $createdAt, updatedAt: $updatedAt, hasFilters: $hasFilters, tagLinkId: $tagLinkId, tagIds: $tagIds, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ProfileNewModelCopyWith<$Res>  {
  factory $ProfileNewModelCopyWith(ProfileNewModel value, $Res Function(ProfileNewModel) _then) = _$ProfileNewModelCopyWithImpl;
@useResult
$Res call({
 String id, String? email,@JsonKey(name: 'full_name') String? fullName, String? username,@JsonKey(name: 'city_code') String? cityCodeRaw,@JsonKey(name: 'country_code') String? countryCodeRaw,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'background_url') String? backgroundUrl, String? bio, String? phone,@JsonKey(name: 'followers_count') int followersCount,@JsonKey(name: 'following_count') int followingCount,@JsonKey(name: 'cluster_count') int clusterCount,@JsonKey(name: 'post_count') int postCount,@JsonKey(name: 'username_change_count') int usernameChangeCount,@JsonKey(name: 'username_next_change_allowed_at') DateTime? usernameNextChangeAllowedAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'has_filters') bool hasFilters,@JsonKey(name: 'tag_link_id') String? tagLinkId,@JsonKey(name: 'tag_ids') List<String> tagIds,@JsonKey(includeFromJson: false, includeToJson: false) List<MarkerTagModel> tags
});




}
/// @nodoc
class _$ProfileNewModelCopyWithImpl<$Res>
    implements $ProfileNewModelCopyWith<$Res> {
  _$ProfileNewModelCopyWithImpl(this._self, this._then);

  final ProfileNewModel _self;
  final $Res Function(ProfileNewModel) _then;

/// Create a copy of ProfileNewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = freezed,Object? fullName = freezed,Object? username = freezed,Object? cityCodeRaw = freezed,Object? countryCodeRaw = freezed,Object? avatarUrl = freezed,Object? backgroundUrl = freezed,Object? bio = freezed,Object? phone = freezed,Object? followersCount = null,Object? followingCount = null,Object? clusterCount = null,Object? postCount = null,Object? usernameChangeCount = null,Object? usernameNextChangeAllowedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? hasFilters = null,Object? tagLinkId = freezed,Object? tagIds = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,cityCodeRaw: freezed == cityCodeRaw ? _self.cityCodeRaw : cityCodeRaw // ignore: cast_nullable_to_non_nullable
as String?,countryCodeRaw: freezed == countryCodeRaw ? _self.countryCodeRaw : countryCodeRaw // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,clusterCount: null == clusterCount ? _self.clusterCount : clusterCount // ignore: cast_nullable_to_non_nullable
as int,postCount: null == postCount ? _self.postCount : postCount // ignore: cast_nullable_to_non_nullable
as int,usernameChangeCount: null == usernameChangeCount ? _self.usernameChangeCount : usernameChangeCount // ignore: cast_nullable_to_non_nullable
as int,usernameNextChangeAllowedAt: freezed == usernameNextChangeAllowedAt ? _self.usernameNextChangeAllowedAt : usernameNextChangeAllowedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasFilters: null == hasFilters ? _self.hasFilters : hasFilters // ignore: cast_nullable_to_non_nullable
as bool,tagLinkId: freezed == tagLinkId ? _self.tagLinkId : tagLinkId // ignore: cast_nullable_to_non_nullable
as String?,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<MarkerTagModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileNewModel].
extension ProfileNewModelPatterns on ProfileNewModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileNewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileNewModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileNewModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileNewModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileNewModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileNewModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? email, @JsonKey(name: 'full_name')  String? fullName,  String? username, @JsonKey(name: 'city_code')  String? cityCodeRaw, @JsonKey(name: 'country_code')  String? countryCodeRaw, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'background_url')  String? backgroundUrl,  String? bio,  String? phone, @JsonKey(name: 'followers_count')  int followersCount, @JsonKey(name: 'following_count')  int followingCount, @JsonKey(name: 'cluster_count')  int clusterCount, @JsonKey(name: 'post_count')  int postCount, @JsonKey(name: 'username_change_count')  int usernameChangeCount, @JsonKey(name: 'username_next_change_allowed_at')  DateTime? usernameNextChangeAllowedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'has_filters')  bool hasFilters, @JsonKey(name: 'tag_link_id')  String? tagLinkId, @JsonKey(name: 'tag_ids')  List<String> tagIds, @JsonKey(includeFromJson: false, includeToJson: false)  List<MarkerTagModel> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileNewModel() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.username,_that.cityCodeRaw,_that.countryCodeRaw,_that.avatarUrl,_that.backgroundUrl,_that.bio,_that.phone,_that.followersCount,_that.followingCount,_that.clusterCount,_that.postCount,_that.usernameChangeCount,_that.usernameNextChangeAllowedAt,_that.createdAt,_that.updatedAt,_that.hasFilters,_that.tagLinkId,_that.tagIds,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? email, @JsonKey(name: 'full_name')  String? fullName,  String? username, @JsonKey(name: 'city_code')  String? cityCodeRaw, @JsonKey(name: 'country_code')  String? countryCodeRaw, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'background_url')  String? backgroundUrl,  String? bio,  String? phone, @JsonKey(name: 'followers_count')  int followersCount, @JsonKey(name: 'following_count')  int followingCount, @JsonKey(name: 'cluster_count')  int clusterCount, @JsonKey(name: 'post_count')  int postCount, @JsonKey(name: 'username_change_count')  int usernameChangeCount, @JsonKey(name: 'username_next_change_allowed_at')  DateTime? usernameNextChangeAllowedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'has_filters')  bool hasFilters, @JsonKey(name: 'tag_link_id')  String? tagLinkId, @JsonKey(name: 'tag_ids')  List<String> tagIds, @JsonKey(includeFromJson: false, includeToJson: false)  List<MarkerTagModel> tags)  $default,) {final _that = this;
switch (_that) {
case _ProfileNewModel():
return $default(_that.id,_that.email,_that.fullName,_that.username,_that.cityCodeRaw,_that.countryCodeRaw,_that.avatarUrl,_that.backgroundUrl,_that.bio,_that.phone,_that.followersCount,_that.followingCount,_that.clusterCount,_that.postCount,_that.usernameChangeCount,_that.usernameNextChangeAllowedAt,_that.createdAt,_that.updatedAt,_that.hasFilters,_that.tagLinkId,_that.tagIds,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? email, @JsonKey(name: 'full_name')  String? fullName,  String? username, @JsonKey(name: 'city_code')  String? cityCodeRaw, @JsonKey(name: 'country_code')  String? countryCodeRaw, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'background_url')  String? backgroundUrl,  String? bio,  String? phone, @JsonKey(name: 'followers_count')  int followersCount, @JsonKey(name: 'following_count')  int followingCount, @JsonKey(name: 'cluster_count')  int clusterCount, @JsonKey(name: 'post_count')  int postCount, @JsonKey(name: 'username_change_count')  int usernameChangeCount, @JsonKey(name: 'username_next_change_allowed_at')  DateTime? usernameNextChangeAllowedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'has_filters')  bool hasFilters, @JsonKey(name: 'tag_link_id')  String? tagLinkId, @JsonKey(name: 'tag_ids')  List<String> tagIds, @JsonKey(includeFromJson: false, includeToJson: false)  List<MarkerTagModel> tags)?  $default,) {final _that = this;
switch (_that) {
case _ProfileNewModel() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.username,_that.cityCodeRaw,_that.countryCodeRaw,_that.avatarUrl,_that.backgroundUrl,_that.bio,_that.phone,_that.followersCount,_that.followingCount,_that.clusterCount,_that.postCount,_that.usernameChangeCount,_that.usernameNextChangeAllowedAt,_that.createdAt,_that.updatedAt,_that.hasFilters,_that.tagLinkId,_that.tagIds,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileNewModel extends ProfileNewModel {
  const _ProfileNewModel({required this.id, this.email, @JsonKey(name: 'full_name') this.fullName, this.username, @JsonKey(name: 'city_code') this.cityCodeRaw, @JsonKey(name: 'country_code') this.countryCodeRaw, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'background_url') this.backgroundUrl, this.bio, this.phone, @JsonKey(name: 'followers_count') this.followersCount = 0, @JsonKey(name: 'following_count') this.followingCount = 0, @JsonKey(name: 'cluster_count') this.clusterCount = 0, @JsonKey(name: 'post_count') this.postCount = 0, @JsonKey(name: 'username_change_count') this.usernameChangeCount = 0, @JsonKey(name: 'username_next_change_allowed_at') this.usernameNextChangeAllowedAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'has_filters') this.hasFilters = false, @JsonKey(name: 'tag_link_id') this.tagLinkId, @JsonKey(name: 'tag_ids') final  List<String> tagIds = const [], @JsonKey(includeFromJson: false, includeToJson: false) final  List<MarkerTagModel> tags = const []}): _tagIds = tagIds,_tags = tags,super._();
  factory _ProfileNewModel.fromJson(Map<String, dynamic> json) => _$ProfileNewModelFromJson(json);

@override final  String id;
@override final  String? email;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override final  String? username;
@override@JsonKey(name: 'city_code') final  String? cityCodeRaw;
@override@JsonKey(name: 'country_code') final  String? countryCodeRaw;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'background_url') final  String? backgroundUrl;
@override final  String? bio;
@override final  String? phone;
@override@JsonKey(name: 'followers_count') final  int followersCount;
@override@JsonKey(name: 'following_count') final  int followingCount;
@override@JsonKey(name: 'cluster_count') final  int clusterCount;
@override@JsonKey(name: 'post_count') final  int postCount;
@override@JsonKey(name: 'username_change_count') final  int usernameChangeCount;
@override@JsonKey(name: 'username_next_change_allowed_at') final  DateTime? usernameNextChangeAllowedAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'has_filters') final  bool hasFilters;
@override@JsonKey(name: 'tag_link_id') final  String? tagLinkId;
 final  List<String> _tagIds;
@override@JsonKey(name: 'tag_ids') List<String> get tagIds {
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tagIds);
}

 final  List<MarkerTagModel> _tags;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<MarkerTagModel> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of ProfileNewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileNewModelCopyWith<_ProfileNewModel> get copyWith => __$ProfileNewModelCopyWithImpl<_ProfileNewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileNewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileNewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.username, username) || other.username == username)&&(identical(other.cityCodeRaw, cityCodeRaw) || other.cityCodeRaw == cityCodeRaw)&&(identical(other.countryCodeRaw, countryCodeRaw) || other.countryCodeRaw == countryCodeRaw)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.clusterCount, clusterCount) || other.clusterCount == clusterCount)&&(identical(other.postCount, postCount) || other.postCount == postCount)&&(identical(other.usernameChangeCount, usernameChangeCount) || other.usernameChangeCount == usernameChangeCount)&&(identical(other.usernameNextChangeAllowedAt, usernameNextChangeAllowedAt) || other.usernameNextChangeAllowedAt == usernameNextChangeAllowedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasFilters, hasFilters) || other.hasFilters == hasFilters)&&(identical(other.tagLinkId, tagLinkId) || other.tagLinkId == tagLinkId)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,email,fullName,username,cityCodeRaw,countryCodeRaw,avatarUrl,backgroundUrl,bio,phone,followersCount,followingCount,clusterCount,postCount,usernameChangeCount,usernameNextChangeAllowedAt,createdAt,updatedAt,hasFilters,tagLinkId,const DeepCollectionEquality().hash(_tagIds),const DeepCollectionEquality().hash(_tags)]);

@override
String toString() {
  return 'ProfileNewModel(id: $id, email: $email, fullName: $fullName, username: $username, cityCodeRaw: $cityCodeRaw, countryCodeRaw: $countryCodeRaw, avatarUrl: $avatarUrl, backgroundUrl: $backgroundUrl, bio: $bio, phone: $phone, followersCount: $followersCount, followingCount: $followingCount, clusterCount: $clusterCount, postCount: $postCount, usernameChangeCount: $usernameChangeCount, usernameNextChangeAllowedAt: $usernameNextChangeAllowedAt, createdAt: $createdAt, updatedAt: $updatedAt, hasFilters: $hasFilters, tagLinkId: $tagLinkId, tagIds: $tagIds, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ProfileNewModelCopyWith<$Res> implements $ProfileNewModelCopyWith<$Res> {
  factory _$ProfileNewModelCopyWith(_ProfileNewModel value, $Res Function(_ProfileNewModel) _then) = __$ProfileNewModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? email,@JsonKey(name: 'full_name') String? fullName, String? username,@JsonKey(name: 'city_code') String? cityCodeRaw,@JsonKey(name: 'country_code') String? countryCodeRaw,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'background_url') String? backgroundUrl, String? bio, String? phone,@JsonKey(name: 'followers_count') int followersCount,@JsonKey(name: 'following_count') int followingCount,@JsonKey(name: 'cluster_count') int clusterCount,@JsonKey(name: 'post_count') int postCount,@JsonKey(name: 'username_change_count') int usernameChangeCount,@JsonKey(name: 'username_next_change_allowed_at') DateTime? usernameNextChangeAllowedAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'has_filters') bool hasFilters,@JsonKey(name: 'tag_link_id') String? tagLinkId,@JsonKey(name: 'tag_ids') List<String> tagIds,@JsonKey(includeFromJson: false, includeToJson: false) List<MarkerTagModel> tags
});




}
/// @nodoc
class __$ProfileNewModelCopyWithImpl<$Res>
    implements _$ProfileNewModelCopyWith<$Res> {
  __$ProfileNewModelCopyWithImpl(this._self, this._then);

  final _ProfileNewModel _self;
  final $Res Function(_ProfileNewModel) _then;

/// Create a copy of ProfileNewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = freezed,Object? fullName = freezed,Object? username = freezed,Object? cityCodeRaw = freezed,Object? countryCodeRaw = freezed,Object? avatarUrl = freezed,Object? backgroundUrl = freezed,Object? bio = freezed,Object? phone = freezed,Object? followersCount = null,Object? followingCount = null,Object? clusterCount = null,Object? postCount = null,Object? usernameChangeCount = null,Object? usernameNextChangeAllowedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? hasFilters = null,Object? tagLinkId = freezed,Object? tagIds = null,Object? tags = null,}) {
  return _then(_ProfileNewModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,cityCodeRaw: freezed == cityCodeRaw ? _self.cityCodeRaw : cityCodeRaw // ignore: cast_nullable_to_non_nullable
as String?,countryCodeRaw: freezed == countryCodeRaw ? _self.countryCodeRaw : countryCodeRaw // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,clusterCount: null == clusterCount ? _self.clusterCount : clusterCount // ignore: cast_nullable_to_non_nullable
as int,postCount: null == postCount ? _self.postCount : postCount // ignore: cast_nullable_to_non_nullable
as int,usernameChangeCount: null == usernameChangeCount ? _self.usernameChangeCount : usernameChangeCount // ignore: cast_nullable_to_non_nullable
as int,usernameNextChangeAllowedAt: freezed == usernameNextChangeAllowedAt ? _self.usernameNextChangeAllowedAt : usernameNextChangeAllowedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasFilters: null == hasFilters ? _self.hasFilters : hasFilters // ignore: cast_nullable_to_non_nullable
as bool,tagLinkId: freezed == tagLinkId ? _self.tagLinkId : tagLinkId // ignore: cast_nullable_to_non_nullable
as String?,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<MarkerTagModel>,
  ));
}


}

// dart format on
