// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_analytics_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingAnalyticsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingAnalyticsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingAnalyticsState()';
}


}

/// @nodoc
class $BookingAnalyticsStateCopyWith<$Res>  {
$BookingAnalyticsStateCopyWith(BookingAnalyticsState _, $Res Function(BookingAnalyticsState) __);
}


/// Adds pattern-matching-related methods to [BookingAnalyticsState].
extension BookingAnalyticsStatePatterns on BookingAnalyticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( DateTime start,  DateTime end,  String? staffId)?  loading,TResult Function( DateTime start,  DateTime end,  String? staffId,  BookingAnalyticsResult result,  List<BookingServiceExecutor> staff)?  loaded,TResult Function( DateTime start,  DateTime end,  String? staffId,  String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.start,_that.end,_that.staffId);case _Loaded() when loaded != null:
return loaded(_that.start,_that.end,_that.staffId,_that.result,_that.staff);case _Error() when error != null:
return error(_that.start,_that.end,_that.staffId,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( DateTime start,  DateTime end,  String? staffId)  loading,required TResult Function( DateTime start,  DateTime end,  String? staffId,  BookingAnalyticsResult result,  List<BookingServiceExecutor> staff)  loaded,required TResult Function( DateTime start,  DateTime end,  String? staffId,  String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading(_that.start,_that.end,_that.staffId);case _Loaded():
return loaded(_that.start,_that.end,_that.staffId,_that.result,_that.staff);case _Error():
return error(_that.start,_that.end,_that.staffId,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( DateTime start,  DateTime end,  String? staffId)?  loading,TResult? Function( DateTime start,  DateTime end,  String? staffId,  BookingAnalyticsResult result,  List<BookingServiceExecutor> staff)?  loaded,TResult? Function( DateTime start,  DateTime end,  String? staffId,  String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.start,_that.end,_that.staffId);case _Loaded() when loaded != null:
return loaded(_that.start,_that.end,_that.staffId,_that.result,_that.staff);case _Error() when error != null:
return error(_that.start,_that.end,_that.staffId,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements BookingAnalyticsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingAnalyticsState.initial()';
}


}




/// @nodoc


class _Loading implements BookingAnalyticsState {
  const _Loading({required this.start, required this.end, this.staffId});
  

 final  DateTime start;
 final  DateTime end;
 final  String? staffId;

/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.staffId, staffId) || other.staffId == staffId));
}


@override
int get hashCode => Object.hash(runtimeType,start,end,staffId);

@override
String toString() {
  return 'BookingAnalyticsState.loading(start: $start, end: $end, staffId: $staffId)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $BookingAnalyticsStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, String? staffId
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? staffId = freezed,}) {
  return _then(_Loading(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,staffId: freezed == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Loaded implements BookingAnalyticsState {
  const _Loaded({required this.start, required this.end, this.staffId, required this.result, required final  List<BookingServiceExecutor> staff}): _staff = staff;
  

 final  DateTime start;
 final  DateTime end;
 final  String? staffId;
 final  BookingAnalyticsResult result;
 final  List<BookingServiceExecutor> _staff;
 List<BookingServiceExecutor> get staff {
  if (_staff is EqualUnmodifiableListView) return _staff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staff);
}


/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other._staff, _staff));
}


@override
int get hashCode => Object.hash(runtimeType,start,end,staffId,result,const DeepCollectionEquality().hash(_staff));

@override
String toString() {
  return 'BookingAnalyticsState.loaded(start: $start, end: $end, staffId: $staffId, result: $result, staff: $staff)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $BookingAnalyticsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, String? staffId, BookingAnalyticsResult result, List<BookingServiceExecutor> staff
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? staffId = freezed,Object? result = null,Object? staff = null,}) {
  return _then(_Loaded(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,staffId: freezed == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as BookingAnalyticsResult,staff: null == staff ? _self._staff : staff // ignore: cast_nullable_to_non_nullable
as List<BookingServiceExecutor>,
  ));
}


}

/// @nodoc


class _Error implements BookingAnalyticsState {
  const _Error({required this.start, required this.end, this.staffId, required this.message});
  

 final  DateTime start;
 final  DateTime end;
 final  String? staffId;
 final  String message;

/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,start,end,staffId,message);

@override
String toString() {
  return 'BookingAnalyticsState.error(start: $start, end: $end, staffId: $staffId, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BookingAnalyticsStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, String? staffId, String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of BookingAnalyticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? staffId = freezed,Object? message = null,}) {
  return _then(_Error(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,staffId: freezed == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
