// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_patches_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedPatchesState {

 List<SavedPatch> get userPatches; List<SavedPatch> get publicPatches; bool get isLoading; String? get errorMessage;
/// Create a copy of SavedPatchesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedPatchesStateCopyWith<SavedPatchesState> get copyWith => _$SavedPatchesStateCopyWithImpl<SavedPatchesState>(this as SavedPatchesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedPatchesState&&const DeepCollectionEquality().equals(other.userPatches, userPatches)&&const DeepCollectionEquality().equals(other.publicPatches, publicPatches)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(userPatches),const DeepCollectionEquality().hash(publicPatches),isLoading,errorMessage);

@override
String toString() {
  return 'SavedPatchesState(userPatches: $userPatches, publicPatches: $publicPatches, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SavedPatchesStateCopyWith<$Res>  {
  factory $SavedPatchesStateCopyWith(SavedPatchesState value, $Res Function(SavedPatchesState) _then) = _$SavedPatchesStateCopyWithImpl;
@useResult
$Res call({
 List<SavedPatch> userPatches, List<SavedPatch> publicPatches, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$SavedPatchesStateCopyWithImpl<$Res>
    implements $SavedPatchesStateCopyWith<$Res> {
  _$SavedPatchesStateCopyWithImpl(this._self, this._then);

  final SavedPatchesState _self;
  final $Res Function(SavedPatchesState) _then;

/// Create a copy of SavedPatchesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userPatches = null,Object? publicPatches = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
userPatches: null == userPatches ? _self.userPatches : userPatches // ignore: cast_nullable_to_non_nullable
as List<SavedPatch>,publicPatches: null == publicPatches ? _self.publicPatches : publicPatches // ignore: cast_nullable_to_non_nullable
as List<SavedPatch>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedPatchesState].
extension SavedPatchesStatePatterns on SavedPatchesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedPatchesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedPatchesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedPatchesState value)  $default,){
final _that = this;
switch (_that) {
case _SavedPatchesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedPatchesState value)?  $default,){
final _that = this;
switch (_that) {
case _SavedPatchesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedPatch> userPatches,  List<SavedPatch> publicPatches,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedPatchesState() when $default != null:
return $default(_that.userPatches,_that.publicPatches,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedPatch> userPatches,  List<SavedPatch> publicPatches,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SavedPatchesState():
return $default(_that.userPatches,_that.publicPatches,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedPatch> userPatches,  List<SavedPatch> publicPatches,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SavedPatchesState() when $default != null:
return $default(_that.userPatches,_that.publicPatches,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SavedPatchesState implements SavedPatchesState {
  const _SavedPatchesState({final  List<SavedPatch> userPatches = const [], final  List<SavedPatch> publicPatches = const [], this.isLoading = false, this.errorMessage}): _userPatches = userPatches,_publicPatches = publicPatches;
  

 final  List<SavedPatch> _userPatches;
@override@JsonKey() List<SavedPatch> get userPatches {
  if (_userPatches is EqualUnmodifiableListView) return _userPatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userPatches);
}

 final  List<SavedPatch> _publicPatches;
@override@JsonKey() List<SavedPatch> get publicPatches {
  if (_publicPatches is EqualUnmodifiableListView) return _publicPatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_publicPatches);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of SavedPatchesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedPatchesStateCopyWith<_SavedPatchesState> get copyWith => __$SavedPatchesStateCopyWithImpl<_SavedPatchesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedPatchesState&&const DeepCollectionEquality().equals(other._userPatches, _userPatches)&&const DeepCollectionEquality().equals(other._publicPatches, _publicPatches)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_userPatches),const DeepCollectionEquality().hash(_publicPatches),isLoading,errorMessage);

@override
String toString() {
  return 'SavedPatchesState(userPatches: $userPatches, publicPatches: $publicPatches, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SavedPatchesStateCopyWith<$Res> implements $SavedPatchesStateCopyWith<$Res> {
  factory _$SavedPatchesStateCopyWith(_SavedPatchesState value, $Res Function(_SavedPatchesState) _then) = __$SavedPatchesStateCopyWithImpl;
@override @useResult
$Res call({
 List<SavedPatch> userPatches, List<SavedPatch> publicPatches, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$SavedPatchesStateCopyWithImpl<$Res>
    implements _$SavedPatchesStateCopyWith<$Res> {
  __$SavedPatchesStateCopyWithImpl(this._self, this._then);

  final _SavedPatchesState _self;
  final $Res Function(_SavedPatchesState) _then;

/// Create a copy of SavedPatchesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userPatches = null,Object? publicPatches = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_SavedPatchesState(
userPatches: null == userPatches ? _self._userPatches : userPatches // ignore: cast_nullable_to_non_nullable
as List<SavedPatch>,publicPatches: null == publicPatches ? _self._publicPatches : publicPatches // ignore: cast_nullable_to_non_nullable
as List<SavedPatch>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
