// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_profile_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditProfileState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditProfileState()';
}


}

/// @nodoc
class $EditProfileStateCopyWith<$Res>  {
$EditProfileStateCopyWith(EditProfileState _, $Res Function(EditProfileState) __);
}


/// Adds pattern-matching-related methods to [EditProfileState].
extension EditProfileStatePatterns on EditProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditProfileIdle value)?  idle,TResult Function( EditProfileSaving value)?  saving,TResult Function( EditProfileSavingUsername value)?  savingUsername,TResult Function( EditProfileSaved value)?  saved,TResult Function( EditProfileErrorState value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditProfileIdle() when idle != null:
return idle(_that);case EditProfileSaving() when saving != null:
return saving(_that);case EditProfileSavingUsername() when savingUsername != null:
return savingUsername(_that);case EditProfileSaved() when saved != null:
return saved(_that);case EditProfileErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditProfileIdle value)  idle,required TResult Function( EditProfileSaving value)  saving,required TResult Function( EditProfileSavingUsername value)  savingUsername,required TResult Function( EditProfileSaved value)  saved,required TResult Function( EditProfileErrorState value)  error,}){
final _that = this;
switch (_that) {
case EditProfileIdle():
return idle(_that);case EditProfileSaving():
return saving(_that);case EditProfileSavingUsername():
return savingUsername(_that);case EditProfileSaved():
return saved(_that);case EditProfileErrorState():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditProfileIdle value)?  idle,TResult? Function( EditProfileSaving value)?  saving,TResult? Function( EditProfileSavingUsername value)?  savingUsername,TResult? Function( EditProfileSaved value)?  saved,TResult? Function( EditProfileErrorState value)?  error,}){
final _that = this;
switch (_that) {
case EditProfileIdle() when idle != null:
return idle(_that);case EditProfileSaving() when saving != null:
return saving(_that);case EditProfileSavingUsername() when savingUsername != null:
return savingUsername(_that);case EditProfileSaved() when saved != null:
return saved(_that);case EditProfileErrorState() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  saving,TResult Function()?  savingUsername,TResult Function( ProfileNewModel profile)?  saved,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditProfileIdle() when idle != null:
return idle();case EditProfileSaving() when saving != null:
return saving();case EditProfileSavingUsername() when savingUsername != null:
return savingUsername();case EditProfileSaved() when saved != null:
return saved(_that.profile);case EditProfileErrorState() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  saving,required TResult Function()  savingUsername,required TResult Function( ProfileNewModel profile)  saved,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case EditProfileIdle():
return idle();case EditProfileSaving():
return saving();case EditProfileSavingUsername():
return savingUsername();case EditProfileSaved():
return saved(_that.profile);case EditProfileErrorState():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  saving,TResult? Function()?  savingUsername,TResult? Function( ProfileNewModel profile)?  saved,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case EditProfileIdle() when idle != null:
return idle();case EditProfileSaving() when saving != null:
return saving();case EditProfileSavingUsername() when savingUsername != null:
return savingUsername();case EditProfileSaved() when saved != null:
return saved(_that.profile);case EditProfileErrorState() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class EditProfileIdle implements EditProfileState {
  const EditProfileIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditProfileState.idle()';
}


}




/// @nodoc


class EditProfileSaving implements EditProfileState {
  const EditProfileSaving();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileSaving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditProfileState.saving()';
}


}




/// @nodoc


class EditProfileSavingUsername implements EditProfileState {
  const EditProfileSavingUsername();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileSavingUsername);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditProfileState.savingUsername()';
}


}




/// @nodoc


class EditProfileSaved implements EditProfileState {
  const EditProfileSaved(this.profile);
  

 final  ProfileNewModel profile;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditProfileSavedCopyWith<EditProfileSaved> get copyWith => _$EditProfileSavedCopyWithImpl<EditProfileSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileSaved&&(identical(other.profile, profile) || other.profile == profile));
}


@override
int get hashCode => Object.hash(runtimeType,profile);

@override
String toString() {
  return 'EditProfileState.saved(profile: $profile)';
}


}

/// @nodoc
abstract mixin class $EditProfileSavedCopyWith<$Res> implements $EditProfileStateCopyWith<$Res> {
  factory $EditProfileSavedCopyWith(EditProfileSaved value, $Res Function(EditProfileSaved) _then) = _$EditProfileSavedCopyWithImpl;
@useResult
$Res call({
 ProfileNewModel profile
});


$ProfileNewModelCopyWith<$Res> get profile;

}
/// @nodoc
class _$EditProfileSavedCopyWithImpl<$Res>
    implements $EditProfileSavedCopyWith<$Res> {
  _$EditProfileSavedCopyWithImpl(this._self, this._then);

  final EditProfileSaved _self;
  final $Res Function(EditProfileSaved) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = null,}) {
  return _then(EditProfileSaved(
null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as ProfileNewModel,
  ));
}

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileNewModelCopyWith<$Res> get profile {
  
  return $ProfileNewModelCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

/// @nodoc


class EditProfileErrorState implements EditProfileState {
  const EditProfileErrorState(this.message);
  

 final  String message;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditProfileErrorStateCopyWith<EditProfileErrorState> get copyWith => _$EditProfileErrorStateCopyWithImpl<EditProfileErrorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileErrorState&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'EditProfileState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $EditProfileErrorStateCopyWith<$Res> implements $EditProfileStateCopyWith<$Res> {
  factory $EditProfileErrorStateCopyWith(EditProfileErrorState value, $Res Function(EditProfileErrorState) _then) = _$EditProfileErrorStateCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$EditProfileErrorStateCopyWithImpl<$Res>
    implements $EditProfileErrorStateCopyWith<$Res> {
  _$EditProfileErrorStateCopyWithImpl(this._self, this._then);

  final EditProfileErrorState _self;
  final $Res Function(EditProfileErrorState) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(EditProfileErrorState(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
