// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bonus_program_settings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BonusProgramSettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BonusProgramSettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BonusProgramSettingsState()';
}


}

/// @nodoc
class $BonusProgramSettingsStateCopyWith<$Res>  {
$BonusProgramSettingsStateCopyWith(BonusProgramSettingsState _, $Res Function(BonusProgramSettingsState) __);
}


/// Adds pattern-matching-related methods to [BonusProgramSettingsState].
extension BonusProgramSettingsStatePatterns on BonusProgramSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BonusProgramSettingsInitial value)?  initial,TResult Function( BonusProgramSettingsReady value)?  ready,TResult Function( BonusProgramSettingsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BonusProgramSettingsInitial() when initial != null:
return initial(_that);case BonusProgramSettingsReady() when ready != null:
return ready(_that);case BonusProgramSettingsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BonusProgramSettingsInitial value)  initial,required TResult Function( BonusProgramSettingsReady value)  ready,required TResult Function( BonusProgramSettingsError value)  error,}){
final _that = this;
switch (_that) {
case BonusProgramSettingsInitial():
return initial(_that);case BonusProgramSettingsReady():
return ready(_that);case BonusProgramSettingsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BonusProgramSettingsInitial value)?  initial,TResult? Function( BonusProgramSettingsReady value)?  ready,TResult? Function( BonusProgramSettingsError value)?  error,}){
final _that = this;
switch (_that) {
case BonusProgramSettingsInitial() when initial != null:
return initial(_that);case BonusProgramSettingsReady() when ready != null:
return ready(_that);case BonusProgramSettingsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( BonusProgramSettings initial,  BonusProgramSettings draft,  bool isSaving,  String? errorMessage)?  ready,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BonusProgramSettingsInitial() when initial != null:
return initial();case BonusProgramSettingsReady() when ready != null:
return ready(_that.initial,_that.draft,_that.isSaving,_that.errorMessage);case BonusProgramSettingsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( BonusProgramSettings initial,  BonusProgramSettings draft,  bool isSaving,  String? errorMessage)  ready,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case BonusProgramSettingsInitial():
return initial();case BonusProgramSettingsReady():
return ready(_that.initial,_that.draft,_that.isSaving,_that.errorMessage);case BonusProgramSettingsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( BonusProgramSettings initial,  BonusProgramSettings draft,  bool isSaving,  String? errorMessage)?  ready,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case BonusProgramSettingsInitial() when initial != null:
return initial();case BonusProgramSettingsReady() when ready != null:
return ready(_that.initial,_that.draft,_that.isSaving,_that.errorMessage);case BonusProgramSettingsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class BonusProgramSettingsInitial implements BonusProgramSettingsState {
  const BonusProgramSettingsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BonusProgramSettingsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BonusProgramSettingsState.initial()';
}


}




/// @nodoc


class BonusProgramSettingsReady implements BonusProgramSettingsState {
  const BonusProgramSettingsReady({required this.initial, required this.draft, this.isSaving = false, this.errorMessage});
  

 final  BonusProgramSettings initial;
 final  BonusProgramSettings draft;
@JsonKey() final  bool isSaving;
 final  String? errorMessage;

/// Create a copy of BonusProgramSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BonusProgramSettingsReadyCopyWith<BonusProgramSettingsReady> get copyWith => _$BonusProgramSettingsReadyCopyWithImpl<BonusProgramSettingsReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BonusProgramSettingsReady&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,initial,draft,isSaving,errorMessage);

@override
String toString() {
  return 'BonusProgramSettingsState.ready(initial: $initial, draft: $draft, isSaving: $isSaving, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $BonusProgramSettingsReadyCopyWith<$Res> implements $BonusProgramSettingsStateCopyWith<$Res> {
  factory $BonusProgramSettingsReadyCopyWith(BonusProgramSettingsReady value, $Res Function(BonusProgramSettingsReady) _then) = _$BonusProgramSettingsReadyCopyWithImpl;
@useResult
$Res call({
 BonusProgramSettings initial, BonusProgramSettings draft, bool isSaving, String? errorMessage
});




}
/// @nodoc
class _$BonusProgramSettingsReadyCopyWithImpl<$Res>
    implements $BonusProgramSettingsReadyCopyWith<$Res> {
  _$BonusProgramSettingsReadyCopyWithImpl(this._self, this._then);

  final BonusProgramSettingsReady _self;
  final $Res Function(BonusProgramSettingsReady) _then;

/// Create a copy of BonusProgramSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? initial = null,Object? draft = null,Object? isSaving = null,Object? errorMessage = freezed,}) {
  return _then(BonusProgramSettingsReady(
initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as BonusProgramSettings,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as BonusProgramSettings,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class BonusProgramSettingsError implements BonusProgramSettingsState {
  const BonusProgramSettingsError(this.message);
  

 final  String message;

/// Create a copy of BonusProgramSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BonusProgramSettingsErrorCopyWith<BonusProgramSettingsError> get copyWith => _$BonusProgramSettingsErrorCopyWithImpl<BonusProgramSettingsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BonusProgramSettingsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BonusProgramSettingsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $BonusProgramSettingsErrorCopyWith<$Res> implements $BonusProgramSettingsStateCopyWith<$Res> {
  factory $BonusProgramSettingsErrorCopyWith(BonusProgramSettingsError value, $Res Function(BonusProgramSettingsError) _then) = _$BonusProgramSettingsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$BonusProgramSettingsErrorCopyWithImpl<$Res>
    implements $BonusProgramSettingsErrorCopyWith<$Res> {
  _$BonusProgramSettingsErrorCopyWithImpl(this._self, this._then);

  final BonusProgramSettingsError _self;
  final $Res Function(BonusProgramSettingsError) _then;

/// Create a copy of BonusProgramSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(BonusProgramSettingsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
