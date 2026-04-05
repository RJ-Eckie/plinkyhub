// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_samples_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedSamplesState {

 List<SavedSample> get userSamples; List<SavedSample> get starredSamples; List<SavedSample> get publicSamples; bool get isLoading; bool get hasLoadedUserItems; bool get hasLoadedPublicItems; String? get errorMessage;
/// Create a copy of SavedSamplesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedSamplesStateCopyWith<SavedSamplesState> get copyWith => _$SavedSamplesStateCopyWithImpl<SavedSamplesState>(this as SavedSamplesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedSamplesState&&const DeepCollectionEquality().equals(other.userSamples, userSamples)&&const DeepCollectionEquality().equals(other.starredSamples, starredSamples)&&const DeepCollectionEquality().equals(other.publicSamples, publicSamples)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasLoadedUserItems, hasLoadedUserItems) || other.hasLoadedUserItems == hasLoadedUserItems)&&(identical(other.hasLoadedPublicItems, hasLoadedPublicItems) || other.hasLoadedPublicItems == hasLoadedPublicItems)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(userSamples),const DeepCollectionEquality().hash(starredSamples),const DeepCollectionEquality().hash(publicSamples),isLoading,hasLoadedUserItems,hasLoadedPublicItems,errorMessage);

@override
String toString() {
  return 'SavedSamplesState(userSamples: $userSamples, starredSamples: $starredSamples, publicSamples: $publicSamples, isLoading: $isLoading, hasLoadedUserItems: $hasLoadedUserItems, hasLoadedPublicItems: $hasLoadedPublicItems, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SavedSamplesStateCopyWith<$Res>  {
  factory $SavedSamplesStateCopyWith(SavedSamplesState value, $Res Function(SavedSamplesState) _then) = _$SavedSamplesStateCopyWithImpl;
@useResult
$Res call({
 List<SavedSample> userSamples, List<SavedSample> starredSamples, List<SavedSample> publicSamples, bool isLoading, bool hasLoadedUserItems, bool hasLoadedPublicItems, String? errorMessage
});




}
/// @nodoc
class _$SavedSamplesStateCopyWithImpl<$Res>
    implements $SavedSamplesStateCopyWith<$Res> {
  _$SavedSamplesStateCopyWithImpl(this._self, this._then);

  final SavedSamplesState _self;
  final $Res Function(SavedSamplesState) _then;

/// Create a copy of SavedSamplesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userSamples = null,Object? starredSamples = null,Object? publicSamples = null,Object? isLoading = null,Object? hasLoadedUserItems = null,Object? hasLoadedPublicItems = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
userSamples: null == userSamples ? _self.userSamples : userSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,starredSamples: null == starredSamples ? _self.starredSamples : starredSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,publicSamples: null == publicSamples ? _self.publicSamples : publicSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasLoadedUserItems: null == hasLoadedUserItems ? _self.hasLoadedUserItems : hasLoadedUserItems // ignore: cast_nullable_to_non_nullable
as bool,hasLoadedPublicItems: null == hasLoadedPublicItems ? _self.hasLoadedPublicItems : hasLoadedPublicItems // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedSamplesState].
extension SavedSamplesStatePatterns on SavedSamplesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedSamplesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedSamplesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedSamplesState value)  $default,){
final _that = this;
switch (_that) {
case _SavedSamplesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedSamplesState value)?  $default,){
final _that = this;
switch (_that) {
case _SavedSamplesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedSample> userSamples,  List<SavedSample> starredSamples,  List<SavedSample> publicSamples,  bool isLoading,  bool hasLoadedUserItems,  bool hasLoadedPublicItems,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedSamplesState() when $default != null:
return $default(_that.userSamples,_that.starredSamples,_that.publicSamples,_that.isLoading,_that.hasLoadedUserItems,_that.hasLoadedPublicItems,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedSample> userSamples,  List<SavedSample> starredSamples,  List<SavedSample> publicSamples,  bool isLoading,  bool hasLoadedUserItems,  bool hasLoadedPublicItems,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SavedSamplesState():
return $default(_that.userSamples,_that.starredSamples,_that.publicSamples,_that.isLoading,_that.hasLoadedUserItems,_that.hasLoadedPublicItems,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedSample> userSamples,  List<SavedSample> starredSamples,  List<SavedSample> publicSamples,  bool isLoading,  bool hasLoadedUserItems,  bool hasLoadedPublicItems,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SavedSamplesState() when $default != null:
return $default(_that.userSamples,_that.starredSamples,_that.publicSamples,_that.isLoading,_that.hasLoadedUserItems,_that.hasLoadedPublicItems,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SavedSamplesState implements SavedSamplesState {
  const _SavedSamplesState({final  List<SavedSample> userSamples = const [], final  List<SavedSample> starredSamples = const [], final  List<SavedSample> publicSamples = const [], this.isLoading = false, this.hasLoadedUserItems = false, this.hasLoadedPublicItems = false, this.errorMessage}): _userSamples = userSamples,_starredSamples = starredSamples,_publicSamples = publicSamples;
  

 final  List<SavedSample> _userSamples;
@override@JsonKey() List<SavedSample> get userSamples {
  if (_userSamples is EqualUnmodifiableListView) return _userSamples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userSamples);
}

 final  List<SavedSample> _starredSamples;
@override@JsonKey() List<SavedSample> get starredSamples {
  if (_starredSamples is EqualUnmodifiableListView) return _starredSamples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_starredSamples);
}

 final  List<SavedSample> _publicSamples;
@override@JsonKey() List<SavedSample> get publicSamples {
  if (_publicSamples is EqualUnmodifiableListView) return _publicSamples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_publicSamples);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool hasLoadedUserItems;
@override@JsonKey() final  bool hasLoadedPublicItems;
@override final  String? errorMessage;

/// Create a copy of SavedSamplesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedSamplesStateCopyWith<_SavedSamplesState> get copyWith => __$SavedSamplesStateCopyWithImpl<_SavedSamplesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedSamplesState&&const DeepCollectionEquality().equals(other._userSamples, _userSamples)&&const DeepCollectionEquality().equals(other._starredSamples, _starredSamples)&&const DeepCollectionEquality().equals(other._publicSamples, _publicSamples)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasLoadedUserItems, hasLoadedUserItems) || other.hasLoadedUserItems == hasLoadedUserItems)&&(identical(other.hasLoadedPublicItems, hasLoadedPublicItems) || other.hasLoadedPublicItems == hasLoadedPublicItems)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_userSamples),const DeepCollectionEquality().hash(_starredSamples),const DeepCollectionEquality().hash(_publicSamples),isLoading,hasLoadedUserItems,hasLoadedPublicItems,errorMessage);

@override
String toString() {
  return 'SavedSamplesState(userSamples: $userSamples, starredSamples: $starredSamples, publicSamples: $publicSamples, isLoading: $isLoading, hasLoadedUserItems: $hasLoadedUserItems, hasLoadedPublicItems: $hasLoadedPublicItems, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SavedSamplesStateCopyWith<$Res> implements $SavedSamplesStateCopyWith<$Res> {
  factory _$SavedSamplesStateCopyWith(_SavedSamplesState value, $Res Function(_SavedSamplesState) _then) = __$SavedSamplesStateCopyWithImpl;
@override @useResult
$Res call({
 List<SavedSample> userSamples, List<SavedSample> starredSamples, List<SavedSample> publicSamples, bool isLoading, bool hasLoadedUserItems, bool hasLoadedPublicItems, String? errorMessage
});




}
/// @nodoc
class __$SavedSamplesStateCopyWithImpl<$Res>
    implements _$SavedSamplesStateCopyWith<$Res> {
  __$SavedSamplesStateCopyWithImpl(this._self, this._then);

  final _SavedSamplesState _self;
  final $Res Function(_SavedSamplesState) _then;

/// Create a copy of SavedSamplesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userSamples = null,Object? starredSamples = null,Object? publicSamples = null,Object? isLoading = null,Object? hasLoadedUserItems = null,Object? hasLoadedPublicItems = null,Object? errorMessage = freezed,}) {
  return _then(_SavedSamplesState(
userSamples: null == userSamples ? _self._userSamples : userSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,starredSamples: null == starredSamples ? _self._starredSamples : starredSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,publicSamples: null == publicSamples ? _self._publicSamples : publicSamples // ignore: cast_nullable_to_non_nullable
as List<SavedSample>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasLoadedUserItems: null == hasLoadedUserItems ? _self.hasLoadedUserItems : hasLoadedUserItems // ignore: cast_nullable_to_non_nullable
as bool,hasLoadedPublicItems: null == hasLoadedPublicItems ? _self.hasLoadedPublicItems : hasLoadedPublicItems // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
