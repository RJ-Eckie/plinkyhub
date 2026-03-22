// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_banks_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedBanksState {

 List<SavedBank> get userBanks; List<SavedBank> get publicBanks; bool get isLoading; String? get errorMessage;
/// Create a copy of SavedBanksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedBanksStateCopyWith<SavedBanksState> get copyWith => _$SavedBanksStateCopyWithImpl<SavedBanksState>(this as SavedBanksState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedBanksState&&const DeepCollectionEquality().equals(other.userBanks, userBanks)&&const DeepCollectionEquality().equals(other.publicBanks, publicBanks)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(userBanks),const DeepCollectionEquality().hash(publicBanks),isLoading,errorMessage);

@override
String toString() {
  return 'SavedBanksState(userBanks: $userBanks, publicBanks: $publicBanks, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SavedBanksStateCopyWith<$Res>  {
  factory $SavedBanksStateCopyWith(SavedBanksState value, $Res Function(SavedBanksState) _then) = _$SavedBanksStateCopyWithImpl;
@useResult
$Res call({
 List<SavedBank> userBanks, List<SavedBank> publicBanks, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$SavedBanksStateCopyWithImpl<$Res>
    implements $SavedBanksStateCopyWith<$Res> {
  _$SavedBanksStateCopyWithImpl(this._self, this._then);

  final SavedBanksState _self;
  final $Res Function(SavedBanksState) _then;

/// Create a copy of SavedBanksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userBanks = null,Object? publicBanks = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
userBanks: null == userBanks ? _self.userBanks : userBanks // ignore: cast_nullable_to_non_nullable
as List<SavedBank>,publicBanks: null == publicBanks ? _self.publicBanks : publicBanks // ignore: cast_nullable_to_non_nullable
as List<SavedBank>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedBanksState].
extension SavedBanksStatePatterns on SavedBanksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedBanksState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedBanksState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedBanksState value)  $default,){
final _that = this;
switch (_that) {
case _SavedBanksState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedBanksState value)?  $default,){
final _that = this;
switch (_that) {
case _SavedBanksState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedBank> userBanks,  List<SavedBank> publicBanks,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedBanksState() when $default != null:
return $default(_that.userBanks,_that.publicBanks,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedBank> userBanks,  List<SavedBank> publicBanks,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SavedBanksState():
return $default(_that.userBanks,_that.publicBanks,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedBank> userBanks,  List<SavedBank> publicBanks,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SavedBanksState() when $default != null:
return $default(_that.userBanks,_that.publicBanks,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SavedBanksState implements SavedBanksState {
  const _SavedBanksState({final  List<SavedBank> userBanks = const [], final  List<SavedBank> publicBanks = const [], this.isLoading = false, this.errorMessage}): _userBanks = userBanks,_publicBanks = publicBanks;
  

 final  List<SavedBank> _userBanks;
@override@JsonKey() List<SavedBank> get userBanks {
  if (_userBanks is EqualUnmodifiableListView) return _userBanks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userBanks);
}

 final  List<SavedBank> _publicBanks;
@override@JsonKey() List<SavedBank> get publicBanks {
  if (_publicBanks is EqualUnmodifiableListView) return _publicBanks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_publicBanks);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of SavedBanksState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedBanksStateCopyWith<_SavedBanksState> get copyWith => __$SavedBanksStateCopyWithImpl<_SavedBanksState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedBanksState&&const DeepCollectionEquality().equals(other._userBanks, _userBanks)&&const DeepCollectionEquality().equals(other._publicBanks, _publicBanks)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_userBanks),const DeepCollectionEquality().hash(_publicBanks),isLoading,errorMessage);

@override
String toString() {
  return 'SavedBanksState(userBanks: $userBanks, publicBanks: $publicBanks, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SavedBanksStateCopyWith<$Res> implements $SavedBanksStateCopyWith<$Res> {
  factory _$SavedBanksStateCopyWith(_SavedBanksState value, $Res Function(_SavedBanksState) _then) = __$SavedBanksStateCopyWithImpl;
@override @useResult
$Res call({
 List<SavedBank> userBanks, List<SavedBank> publicBanks, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$SavedBanksStateCopyWithImpl<$Res>
    implements _$SavedBanksStateCopyWith<$Res> {
  __$SavedBanksStateCopyWithImpl(this._self, this._then);

  final _SavedBanksState _self;
  final $Res Function(_SavedBanksState) _then;

/// Create a copy of SavedBanksState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userBanks = null,Object? publicBanks = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_SavedBanksState(
userBanks: null == userBanks ? _self._userBanks : userBanks // ignore: cast_nullable_to_non_nullable
as List<SavedBank>,publicBanks: null == publicBanks ? _self._publicBanks : publicBanks // ignore: cast_nullable_to_non_nullable
as List<SavedBank>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
