// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_list_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingListState()';
}


}

/// @nodoc
class $BookingListStateCopyWith<$Res>  {
$BookingListStateCopyWith(BookingListState _, $Res Function(BookingListState) __);
}


/// Adds pattern-matching-related methods to [BookingListState].
extension BookingListStatePatterns on BookingListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( BookingListLoaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case BookingListLoaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( BookingListLoaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case BookingListLoaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( BookingListLoaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case BookingListLoaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( BookingListDateRange period,  String? query)?  loading,TResult Function( BookingListDateRange period,  String? query,  List<BookingListItem> items,  int mainTabIndex,  DateTime? upcomingDay,  bool isFromCache,  bool isRefreshing,  Set<String> updatingIds)?  loaded,TResult Function( BookingListDateRange period,  String? query,  String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.period,_that.query);case BookingListLoaded() when loaded != null:
return loaded(_that.period,_that.query,_that.items,_that.mainTabIndex,_that.upcomingDay,_that.isFromCache,_that.isRefreshing,_that.updatingIds);case _Error() when error != null:
return error(_that.period,_that.query,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( BookingListDateRange period,  String? query)  loading,required TResult Function( BookingListDateRange period,  String? query,  List<BookingListItem> items,  int mainTabIndex,  DateTime? upcomingDay,  bool isFromCache,  bool isRefreshing,  Set<String> updatingIds)  loaded,required TResult Function( BookingListDateRange period,  String? query,  String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading(_that.period,_that.query);case BookingListLoaded():
return loaded(_that.period,_that.query,_that.items,_that.mainTabIndex,_that.upcomingDay,_that.isFromCache,_that.isRefreshing,_that.updatingIds);case _Error():
return error(_that.period,_that.query,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( BookingListDateRange period,  String? query)?  loading,TResult? Function( BookingListDateRange period,  String? query,  List<BookingListItem> items,  int mainTabIndex,  DateTime? upcomingDay,  bool isFromCache,  bool isRefreshing,  Set<String> updatingIds)?  loaded,TResult? Function( BookingListDateRange period,  String? query,  String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.period,_that.query);case BookingListLoaded() when loaded != null:
return loaded(_that.period,_that.query,_that.items,_that.mainTabIndex,_that.upcomingDay,_that.isFromCache,_that.isRefreshing,_that.updatingIds);case _Error() when error != null:
return error(_that.period,_that.query,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements BookingListState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingListState.initial()';
}


}




/// @nodoc


class _Loading implements BookingListState {
  const _Loading({required this.period, this.query});
  

 final  BookingListDateRange period;
 final  String? query;

/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&(identical(other.period, period) || other.period == period)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,period,query);

@override
String toString() {
  return 'BookingListState.loading(period: $period, query: $query)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $BookingListStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String? query
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? query = freezed,}) {
  return _then(_Loading(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class BookingListLoaded implements BookingListState {
  const BookingListLoaded({required this.period, this.query, required final  List<BookingListItem> items, this.mainTabIndex = 1, this.upcomingDay, this.isFromCache = false, this.isRefreshing = false, final  Set<String> updatingIds = const <String>{}}): _items = items,_updatingIds = updatingIds;
  

 final  BookingListDateRange period;
 final  String? query;
 final  List<BookingListItem> _items;
 List<BookingListItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@JsonKey() final  int mainTabIndex;
// BookingHostInboxTab.upcoming
 final  DateTime? upcomingDay;
@JsonKey() final  bool isFromCache;
@JsonKey() final  bool isRefreshing;
 final  Set<String> _updatingIds;
@JsonKey() Set<String> get updatingIds {
  if (_updatingIds is EqualUnmodifiableSetView) return _updatingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_updatingIds);
}


/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingListLoadedCopyWith<BookingListLoaded> get copyWith => _$BookingListLoadedCopyWithImpl<BookingListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingListLoaded&&(identical(other.period, period) || other.period == period)&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.mainTabIndex, mainTabIndex) || other.mainTabIndex == mainTabIndex)&&(identical(other.upcomingDay, upcomingDay) || other.upcomingDay == upcomingDay)&&(identical(other.isFromCache, isFromCache) || other.isFromCache == isFromCache)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&const DeepCollectionEquality().equals(other._updatingIds, _updatingIds));
}


@override
int get hashCode => Object.hash(runtimeType,period,query,const DeepCollectionEquality().hash(_items),mainTabIndex,upcomingDay,isFromCache,isRefreshing,const DeepCollectionEquality().hash(_updatingIds));

@override
String toString() {
  return 'BookingListState.loaded(period: $period, query: $query, items: $items, mainTabIndex: $mainTabIndex, upcomingDay: $upcomingDay, isFromCache: $isFromCache, isRefreshing: $isRefreshing, updatingIds: $updatingIds)';
}


}

/// @nodoc
abstract mixin class $BookingListLoadedCopyWith<$Res> implements $BookingListStateCopyWith<$Res> {
  factory $BookingListLoadedCopyWith(BookingListLoaded value, $Res Function(BookingListLoaded) _then) = _$BookingListLoadedCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String? query, List<BookingListItem> items, int mainTabIndex, DateTime? upcomingDay, bool isFromCache, bool isRefreshing, Set<String> updatingIds
});




}
/// @nodoc
class _$BookingListLoadedCopyWithImpl<$Res>
    implements $BookingListLoadedCopyWith<$Res> {
  _$BookingListLoadedCopyWithImpl(this._self, this._then);

  final BookingListLoaded _self;
  final $Res Function(BookingListLoaded) _then;

/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? query = freezed,Object? items = null,Object? mainTabIndex = null,Object? upcomingDay = freezed,Object? isFromCache = null,Object? isRefreshing = null,Object? updatingIds = null,}) {
  return _then(BookingListLoaded(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BookingListItem>,mainTabIndex: null == mainTabIndex ? _self.mainTabIndex : mainTabIndex // ignore: cast_nullable_to_non_nullable
as int,upcomingDay: freezed == upcomingDay ? _self.upcomingDay : upcomingDay // ignore: cast_nullable_to_non_nullable
as DateTime?,isFromCache: null == isFromCache ? _self.isFromCache : isFromCache // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,updatingIds: null == updatingIds ? _self._updatingIds : updatingIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class _Error implements BookingListState {
  const _Error({required this.period, this.query, required this.message});
  

 final  BookingListDateRange period;
 final  String? query;
 final  String message;

/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.period, period) || other.period == period)&&(identical(other.query, query) || other.query == query)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,period,query,message);

@override
String toString() {
  return 'BookingListState.error(period: $period, query: $query, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BookingListStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 BookingListDateRange period, String? query, String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of BookingListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,Object? query = freezed,Object? message = null,}) {
  return _then(_Error(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BookingListDateRange,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
