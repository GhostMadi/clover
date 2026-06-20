// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employer_work_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployerWorkState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployerWorkState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployerWorkState()';
}


}

/// @nodoc
class $EmployerWorkStateCopyWith<$Res>  {
$EmployerWorkStateCopyWith(EmployerWorkState _, $Res Function(EmployerWorkState) __);
}


/// Adds pattern-matching-related methods to [EmployerWorkState].
extension EmployerWorkStatePatterns on EmployerWorkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( EmployerWorkLoaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case EmployerWorkLoaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( EmployerWorkLoaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case EmployerWorkLoaded():
return loaded(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( EmployerWorkLoaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case EmployerWorkLoaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<WorkRelationModel> relations,  int mainTabIndex)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case EmployerWorkLoaded() when loaded != null:
return loaded(_that.relations,_that.mainTabIndex);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<WorkRelationModel> relations,  int mainTabIndex)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case EmployerWorkLoaded():
return loaded(_that.relations,_that.mainTabIndex);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<WorkRelationModel> relations,  int mainTabIndex)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case EmployerWorkLoaded() when loaded != null:
return loaded(_that.relations,_that.mainTabIndex);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements EmployerWorkState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployerWorkState.initial()';
}


}




/// @nodoc


class _Loading implements EmployerWorkState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployerWorkState.loading()';
}


}




/// @nodoc


class EmployerWorkLoaded implements EmployerWorkState {
  const EmployerWorkLoaded({required final  List<WorkRelationModel> relations, this.mainTabIndex = 0}): _relations = relations;
  

 final  List<WorkRelationModel> _relations;
 List<WorkRelationModel> get relations {
  if (_relations is EqualUnmodifiableListView) return _relations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relations);
}

@JsonKey() final  int mainTabIndex;

/// Create a copy of EmployerWorkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployerWorkLoadedCopyWith<EmployerWorkLoaded> get copyWith => _$EmployerWorkLoadedCopyWithImpl<EmployerWorkLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployerWorkLoaded&&const DeepCollectionEquality().equals(other._relations, _relations)&&(identical(other.mainTabIndex, mainTabIndex) || other.mainTabIndex == mainTabIndex));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_relations),mainTabIndex);

@override
String toString() {
  return 'EmployerWorkState.loaded(relations: $relations, mainTabIndex: $mainTabIndex)';
}


}

/// @nodoc
abstract mixin class $EmployerWorkLoadedCopyWith<$Res> implements $EmployerWorkStateCopyWith<$Res> {
  factory $EmployerWorkLoadedCopyWith(EmployerWorkLoaded value, $Res Function(EmployerWorkLoaded) _then) = _$EmployerWorkLoadedCopyWithImpl;
@useResult
$Res call({
 List<WorkRelationModel> relations, int mainTabIndex
});




}
/// @nodoc
class _$EmployerWorkLoadedCopyWithImpl<$Res>
    implements $EmployerWorkLoadedCopyWith<$Res> {
  _$EmployerWorkLoadedCopyWithImpl(this._self, this._then);

  final EmployerWorkLoaded _self;
  final $Res Function(EmployerWorkLoaded) _then;

/// Create a copy of EmployerWorkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? relations = null,Object? mainTabIndex = null,}) {
  return _then(EmployerWorkLoaded(
relations: null == relations ? _self._relations : relations // ignore: cast_nullable_to_non_nullable
as List<WorkRelationModel>,mainTabIndex: null == mainTabIndex ? _self.mainTabIndex : mainTabIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Error implements EmployerWorkState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of EmployerWorkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'EmployerWorkState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $EmployerWorkStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of EmployerWorkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
