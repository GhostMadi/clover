// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_calendar_bookings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingCalendarBookingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingCalendarBookingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingCalendarBookingsState()';
}


}

/// @nodoc
class $BookingCalendarBookingsStateCopyWith<$Res>  {
$BookingCalendarBookingsStateCopyWith(BookingCalendarBookingsState _, $Res Function(BookingCalendarBookingsState) __);
}


/// Adds pattern-matching-related methods to [BookingCalendarBookingsState].
extension BookingCalendarBookingsStatePatterns on BookingCalendarBookingsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( BookingListDateRange period,  String hostId)?  loading,TResult Function( BookingListDateRange period,  String hostId,  List<BookingCalendarItem> items,  bool isRefreshing)?  loaded,TResult Function( BookingListDateRange period,  String hostId,  String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.period,_that.hostId);case _Loaded() when loaded != null:
return loaded(_that.period,_that.hostId,_that.items,_that.isRefreshing);case _Error() when error != null:
return error(_that.period,_that.hostId,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( BookingListDateRange period,  String hostId)  loading,required TResult Function( BookingListDateRange period,  String hostId,  List<BookingCalendarItem> items,  bool isRefreshing)  loaded,required TResult Function( BookingListDateRange period,  String hostId,  String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading(_that.period,_that.hostId);case _Loaded():
return loaded(_that.period,_that.hostId,_that.items,_that.isRefreshing);case _Error():
return error(_that.period,_that.hostId,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( BookingListDateRange period,  String hostId)?  loading,TResult? Function( BookingListDateRange period,  String hostId,  List<BookingCalendarItem> items,  bool isRefreshing)?  loaded,TResult? Function( BookingListDateRange period,  String hostId,  String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.period,_that.hostId);case _Loaded() when loaded != null:
return loaded(_that.period,_that.hostId,_that.items,_that.isRefreshing);case _Error() when error != null:
return error(_that.period,_that.hostId,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements BookingCalendarBookingsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingCalendarBookingsState.initial()';
}


}




/// @nodoc


class _Loading implements BookingCalendarBookingsState {
  const _Loading({required this.period, required this.hostId});
  

 final  BookingListDateRange period;
 final  String hostId;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&(identical(other.period, period) || other.period == period)&&(identical(other.hostId, hostId) || other.hostId == hostId));
}


@override
int get hashCode => Object.hash(runtimeType,period,hostId);

@override
String toString() {
  return 'BookingCalendarBookingsState.loading(period: $period, hostId: $hostId)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $BookingCalendarBookingsStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String hostId
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? hostId = null,}) {
  return _then(_Loading(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Loaded implements BookingCalendarBookingsState {
  const _Loaded({required this.period, required this.hostId, required final  List<BookingCalendarItem> items, this.isRefreshing = false}): _items = items;
  

 final  BookingListDateRange period;
 final  String hostId;
 final  List<BookingCalendarItem> _items;
 List<BookingCalendarItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@JsonKey() final  bool isRefreshing;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.period, period) || other.period == period)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,period,hostId,const DeepCollectionEquality().hash(_items),isRefreshing);

@override
String toString() {
  return 'BookingCalendarBookingsState.loaded(period: $period, hostId: $hostId, items: $items, isRefreshing: $isRefreshing)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $BookingCalendarBookingsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String hostId, List<BookingCalendarItem> items, bool isRefreshing
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? hostId = null,Object? items = null,Object? isRefreshing = null,}) {
  return _then(_Loaded(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BookingCalendarItem>,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Error implements BookingCalendarBookingsState {
  const _Error({required this.period, required this.hostId, required this.message});
  

 final  BookingListDateRange period;
 final  String hostId;
 final  String message;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.period, period) || other.period == period)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,period,hostId,message);

@override
String toString() {
  return 'BookingCalendarBookingsState.error(period: $period, hostId: $hostId, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BookingCalendarBookingsStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String hostId, String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of BookingCalendarBookingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? hostId = null,Object? message = null,}) {
  return _then(_Error(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
