// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_client_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingClientState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingClientState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingClientState()';
}


}

/// @nodoc
class $BookingClientStateCopyWith<$Res>  {
$BookingClientStateCopyWith(BookingClientState _, $Res Function(BookingClientState) __);
}


/// Adds pattern-matching-related methods to [BookingClientState].
extension BookingClientStatePatterns on BookingClientState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Ready value)?  ready,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Ready() when ready != null:
return ready(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Ready value)  ready,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Ready():
return ready(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Ready value)?  ready,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Ready() when ready != null:
return ready(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String hostId,  String hostDisplayName)?  loading,TResult Function( String hostId,  String hostDisplayName,  List<BookingServiceWithStaff> catalog,  BookingScheduleSettings schedule,  DateTime selectedDay,  BookingService? selectedService,  BookingServiceExecutor? selectedExecutor,  DateTime? selectedSlotStart,  List<ClientBookingSlot> slots,  String? dayUnavailableReason,  String? conflictMessage,  bool isLoadingSlots,  bool isSubmitting)?  ready,TResult Function( String hostId,  String hostDisplayName,  String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.hostId,_that.hostDisplayName);case _Ready() when ready != null:
return ready(_that.hostId,_that.hostDisplayName,_that.catalog,_that.schedule,_that.selectedDay,_that.selectedService,_that.selectedExecutor,_that.selectedSlotStart,_that.slots,_that.dayUnavailableReason,_that.conflictMessage,_that.isLoadingSlots,_that.isSubmitting);case _Error() when error != null:
return error(_that.hostId,_that.hostDisplayName,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String hostId,  String hostDisplayName)  loading,required TResult Function( String hostId,  String hostDisplayName,  List<BookingServiceWithStaff> catalog,  BookingScheduleSettings schedule,  DateTime selectedDay,  BookingService? selectedService,  BookingServiceExecutor? selectedExecutor,  DateTime? selectedSlotStart,  List<ClientBookingSlot> slots,  String? dayUnavailableReason,  String? conflictMessage,  bool isLoadingSlots,  bool isSubmitting)  ready,required TResult Function( String hostId,  String hostDisplayName,  String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading(_that.hostId,_that.hostDisplayName);case _Ready():
return ready(_that.hostId,_that.hostDisplayName,_that.catalog,_that.schedule,_that.selectedDay,_that.selectedService,_that.selectedExecutor,_that.selectedSlotStart,_that.slots,_that.dayUnavailableReason,_that.conflictMessage,_that.isLoadingSlots,_that.isSubmitting);case _Error():
return error(_that.hostId,_that.hostDisplayName,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String hostId,  String hostDisplayName)?  loading,TResult? Function( String hostId,  String hostDisplayName,  List<BookingServiceWithStaff> catalog,  BookingScheduleSettings schedule,  DateTime selectedDay,  BookingService? selectedService,  BookingServiceExecutor? selectedExecutor,  DateTime? selectedSlotStart,  List<ClientBookingSlot> slots,  String? dayUnavailableReason,  String? conflictMessage,  bool isLoadingSlots,  bool isSubmitting)?  ready,TResult? Function( String hostId,  String hostDisplayName,  String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.hostId,_that.hostDisplayName);case _Ready() when ready != null:
return ready(_that.hostId,_that.hostDisplayName,_that.catalog,_that.schedule,_that.selectedDay,_that.selectedService,_that.selectedExecutor,_that.selectedSlotStart,_that.slots,_that.dayUnavailableReason,_that.conflictMessage,_that.isLoadingSlots,_that.isSubmitting);case _Error() when error != null:
return error(_that.hostId,_that.hostDisplayName,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements BookingClientState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookingClientState.initial()';
}


}




/// @nodoc


class _Loading implements BookingClientState {
  const _Loading({required this.hostId, required this.hostDisplayName});
  

 final  String hostId;
 final  String hostDisplayName;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.hostDisplayName, hostDisplayName) || other.hostDisplayName == hostDisplayName));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,hostDisplayName);

@override
String toString() {
  return 'BookingClientState.loading(hostId: $hostId, hostDisplayName: $hostDisplayName)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $BookingClientStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@useResult
$Res call({
 String hostId, String hostDisplayName
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hostId = null,Object? hostDisplayName = null,}) {
  return _then(_Loading(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,hostDisplayName: null == hostDisplayName ? _self.hostDisplayName : hostDisplayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Ready implements BookingClientState {
  const _Ready({required this.hostId, required this.hostDisplayName, required final  List<BookingServiceWithStaff> catalog, required this.schedule, required this.selectedDay, this.selectedService, this.selectedExecutor, this.selectedSlotStart, final  List<ClientBookingSlot> slots = const [], this.dayUnavailableReason, this.conflictMessage, this.isLoadingSlots = false, this.isSubmitting = false}): _catalog = catalog,_slots = slots;
  

 final  String hostId;
 final  String hostDisplayName;
 final  List<BookingServiceWithStaff> _catalog;
 List<BookingServiceWithStaff> get catalog {
  if (_catalog is EqualUnmodifiableListView) return _catalog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_catalog);
}

 final  BookingScheduleSettings schedule;
 final  DateTime selectedDay;
 final  BookingService? selectedService;
 final  BookingServiceExecutor? selectedExecutor;
 final  DateTime? selectedSlotStart;
 final  List<ClientBookingSlot> _slots;
@JsonKey() List<ClientBookingSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

 final  String? dayUnavailableReason;
 final  String? conflictMessage;
@JsonKey() final  bool isLoadingSlots;
@JsonKey() final  bool isSubmitting;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadyCopyWith<_Ready> get copyWith => __$ReadyCopyWithImpl<_Ready>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ready&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.hostDisplayName, hostDisplayName) || other.hostDisplayName == hostDisplayName)&&const DeepCollectionEquality().equals(other._catalog, _catalog)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.selectedDay, selectedDay) || other.selectedDay == selectedDay)&&(identical(other.selectedService, selectedService) || other.selectedService == selectedService)&&(identical(other.selectedExecutor, selectedExecutor) || other.selectedExecutor == selectedExecutor)&&(identical(other.selectedSlotStart, selectedSlotStart) || other.selectedSlotStart == selectedSlotStart)&&const DeepCollectionEquality().equals(other._slots, _slots)&&(identical(other.dayUnavailableReason, dayUnavailableReason) || other.dayUnavailableReason == dayUnavailableReason)&&(identical(other.conflictMessage, conflictMessage) || other.conflictMessage == conflictMessage)&&(identical(other.isLoadingSlots, isLoadingSlots) || other.isLoadingSlots == isLoadingSlots)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,hostDisplayName,const DeepCollectionEquality().hash(_catalog),schedule,selectedDay,selectedService,selectedExecutor,selectedSlotStart,const DeepCollectionEquality().hash(_slots),dayUnavailableReason,conflictMessage,isLoadingSlots,isSubmitting);

@override
String toString() {
  return 'BookingClientState.ready(hostId: $hostId, hostDisplayName: $hostDisplayName, catalog: $catalog, schedule: $schedule, selectedDay: $selectedDay, selectedService: $selectedService, selectedExecutor: $selectedExecutor, selectedSlotStart: $selectedSlotStart, slots: $slots, dayUnavailableReason: $dayUnavailableReason, conflictMessage: $conflictMessage, isLoadingSlots: $isLoadingSlots, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class _$ReadyCopyWith<$Res> implements $BookingClientStateCopyWith<$Res> {
  factory _$ReadyCopyWith(_Ready value, $Res Function(_Ready) _then) = __$ReadyCopyWithImpl;
@useResult
$Res call({
 String hostId, String hostDisplayName, List<BookingServiceWithStaff> catalog, BookingScheduleSettings schedule, DateTime selectedDay, BookingService? selectedService, BookingServiceExecutor? selectedExecutor, DateTime? selectedSlotStart, List<ClientBookingSlot> slots, String? dayUnavailableReason, String? conflictMessage, bool isLoadingSlots, bool isSubmitting
});




}
/// @nodoc
class __$ReadyCopyWithImpl<$Res>
    implements _$ReadyCopyWith<$Res> {
  __$ReadyCopyWithImpl(this._self, this._then);

  final _Ready _self;
  final $Res Function(_Ready) _then;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hostId = null,Object? hostDisplayName = null,Object? catalog = null,Object? schedule = null,Object? selectedDay = null,Object? selectedService = freezed,Object? selectedExecutor = freezed,Object? selectedSlotStart = freezed,Object? slots = null,Object? dayUnavailableReason = freezed,Object? conflictMessage = freezed,Object? isLoadingSlots = null,Object? isSubmitting = null,}) {
  return _then(_Ready(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,hostDisplayName: null == hostDisplayName ? _self.hostDisplayName : hostDisplayName // ignore: cast_nullable_to_non_nullable
as String,catalog: null == catalog ? _self._catalog : catalog // ignore: cast_nullable_to_non_nullable
as List<BookingServiceWithStaff>,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as BookingScheduleSettings,selectedDay: null == selectedDay ? _self.selectedDay : selectedDay // ignore: cast_nullable_to_non_nullable
as DateTime,selectedService: freezed == selectedService ? _self.selectedService : selectedService // ignore: cast_nullable_to_non_nullable
as BookingService?,selectedExecutor: freezed == selectedExecutor ? _self.selectedExecutor : selectedExecutor // ignore: cast_nullable_to_non_nullable
as BookingServiceExecutor?,selectedSlotStart: freezed == selectedSlotStart ? _self.selectedSlotStart : selectedSlotStart // ignore: cast_nullable_to_non_nullable
as DateTime?,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<ClientBookingSlot>,dayUnavailableReason: freezed == dayUnavailableReason ? _self.dayUnavailableReason : dayUnavailableReason // ignore: cast_nullable_to_non_nullable
as String?,conflictMessage: freezed == conflictMessage ? _self.conflictMessage : conflictMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoadingSlots: null == isLoadingSlots ? _self.isLoadingSlots : isLoadingSlots // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Error implements BookingClientState {
  const _Error({required this.hostId, required this.hostDisplayName, required this.message});
  

 final  String hostId;
 final  String hostDisplayName;
 final  String message;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.hostDisplayName, hostDisplayName) || other.hostDisplayName == hostDisplayName)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,hostDisplayName,message);

@override
String toString() {
  return 'BookingClientState.error(hostId: $hostId, hostDisplayName: $hostDisplayName, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BookingClientStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String hostId, String hostDisplayName, String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of BookingClientState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hostId = null,Object? hostDisplayName = null,Object? message = null,}) {
  return _then(_Error(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,hostDisplayName: null == hostDisplayName ? _self.hostDisplayName : hostDisplayName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
