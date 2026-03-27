// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayState {

 Uint8List? get sampleWavBytes; String get sampleName; int get sampleBaseMidi; bool get isLoadingSample; Set<int> get activePads; List<double> get slicePoints; List<int> get sliceNotes; bool get pitched;
/// Create a copy of PlayState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayStateCopyWith<PlayState> get copyWith => _$PlayStateCopyWithImpl<PlayState>(this as PlayState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayState&&const DeepCollectionEquality().equals(other.sampleWavBytes, sampleWavBytes)&&(identical(other.sampleName, sampleName) || other.sampleName == sampleName)&&(identical(other.sampleBaseMidi, sampleBaseMidi) || other.sampleBaseMidi == sampleBaseMidi)&&(identical(other.isLoadingSample, isLoadingSample) || other.isLoadingSample == isLoadingSample)&&const DeepCollectionEquality().equals(other.activePads, activePads)&&const DeepCollectionEquality().equals(other.slicePoints, slicePoints)&&const DeepCollectionEquality().equals(other.sliceNotes, sliceNotes)&&(identical(other.pitched, pitched) || other.pitched == pitched));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sampleWavBytes),sampleName,sampleBaseMidi,isLoadingSample,const DeepCollectionEquality().hash(activePads),const DeepCollectionEquality().hash(slicePoints),const DeepCollectionEquality().hash(sliceNotes),pitched);

@override
String toString() {
  return 'PlayState(sampleWavBytes: $sampleWavBytes, sampleName: $sampleName, sampleBaseMidi: $sampleBaseMidi, isLoadingSample: $isLoadingSample, activePads: $activePads, slicePoints: $slicePoints, sliceNotes: $sliceNotes, pitched: $pitched)';
}


}

/// @nodoc
abstract mixin class $PlayStateCopyWith<$Res>  {
  factory $PlayStateCopyWith(PlayState value, $Res Function(PlayState) _then) = _$PlayStateCopyWithImpl;
@useResult
$Res call({
 Uint8List? sampleWavBytes, String sampleName, int sampleBaseMidi, bool isLoadingSample, Set<int> activePads, List<double> slicePoints, List<int> sliceNotes, bool pitched
});




}
/// @nodoc
class _$PlayStateCopyWithImpl<$Res>
    implements $PlayStateCopyWith<$Res> {
  _$PlayStateCopyWithImpl(this._self, this._then);

  final PlayState _self;
  final $Res Function(PlayState) _then;

/// Create a copy of PlayState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sampleWavBytes = freezed,Object? sampleName = null,Object? sampleBaseMidi = null,Object? isLoadingSample = null,Object? activePads = null,Object? slicePoints = null,Object? sliceNotes = null,Object? pitched = null,}) {
  return _then(_self.copyWith(
sampleWavBytes: freezed == sampleWavBytes ? _self.sampleWavBytes : sampleWavBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,sampleName: null == sampleName ? _self.sampleName : sampleName // ignore: cast_nullable_to_non_nullable
as String,sampleBaseMidi: null == sampleBaseMidi ? _self.sampleBaseMidi : sampleBaseMidi // ignore: cast_nullable_to_non_nullable
as int,isLoadingSample: null == isLoadingSample ? _self.isLoadingSample : isLoadingSample // ignore: cast_nullable_to_non_nullable
as bool,activePads: null == activePads ? _self.activePads : activePads // ignore: cast_nullable_to_non_nullable
as Set<int>,slicePoints: null == slicePoints ? _self.slicePoints : slicePoints // ignore: cast_nullable_to_non_nullable
as List<double>,sliceNotes: null == sliceNotes ? _self.sliceNotes : sliceNotes // ignore: cast_nullable_to_non_nullable
as List<int>,pitched: null == pitched ? _self.pitched : pitched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayState].
extension PlayStatePatterns on PlayState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayState value)  $default,){
final _that = this;
switch (_that) {
case _PlayState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uint8List? sampleWavBytes,  String sampleName,  int sampleBaseMidi,  bool isLoadingSample,  Set<int> activePads,  List<double> slicePoints,  List<int> sliceNotes,  bool pitched)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayState() when $default != null:
return $default(_that.sampleWavBytes,_that.sampleName,_that.sampleBaseMidi,_that.isLoadingSample,_that.activePads,_that.slicePoints,_that.sliceNotes,_that.pitched);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uint8List? sampleWavBytes,  String sampleName,  int sampleBaseMidi,  bool isLoadingSample,  Set<int> activePads,  List<double> slicePoints,  List<int> sliceNotes,  bool pitched)  $default,) {final _that = this;
switch (_that) {
case _PlayState():
return $default(_that.sampleWavBytes,_that.sampleName,_that.sampleBaseMidi,_that.isLoadingSample,_that.activePads,_that.slicePoints,_that.sliceNotes,_that.pitched);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uint8List? sampleWavBytes,  String sampleName,  int sampleBaseMidi,  bool isLoadingSample,  Set<int> activePads,  List<double> slicePoints,  List<int> sliceNotes,  bool pitched)?  $default,) {final _that = this;
switch (_that) {
case _PlayState() when $default != null:
return $default(_that.sampleWavBytes,_that.sampleName,_that.sampleBaseMidi,_that.isLoadingSample,_that.activePads,_that.slicePoints,_that.sliceNotes,_that.pitched);case _:
  return null;

}
}

}

/// @nodoc


class _PlayState implements PlayState {
  const _PlayState({this.sampleWavBytes, this.sampleName = '', this.sampleBaseMidi = 60, this.isLoadingSample = false, final  Set<int> activePads = const {}, final  List<double> slicePoints = defaultSlicePoints, final  List<int> sliceNotes = defaultSliceNotes, this.pitched = false}): _activePads = activePads,_slicePoints = slicePoints,_sliceNotes = sliceNotes;
  

@override final  Uint8List? sampleWavBytes;
@override@JsonKey() final  String sampleName;
@override@JsonKey() final  int sampleBaseMidi;
@override@JsonKey() final  bool isLoadingSample;
 final  Set<int> _activePads;
@override@JsonKey() Set<int> get activePads {
  if (_activePads is EqualUnmodifiableSetView) return _activePads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activePads);
}

 final  List<double> _slicePoints;
@override@JsonKey() List<double> get slicePoints {
  if (_slicePoints is EqualUnmodifiableListView) return _slicePoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slicePoints);
}

 final  List<int> _sliceNotes;
@override@JsonKey() List<int> get sliceNotes {
  if (_sliceNotes is EqualUnmodifiableListView) return _sliceNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sliceNotes);
}

@override@JsonKey() final  bool pitched;

/// Create a copy of PlayState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayStateCopyWith<_PlayState> get copyWith => __$PlayStateCopyWithImpl<_PlayState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayState&&const DeepCollectionEquality().equals(other.sampleWavBytes, sampleWavBytes)&&(identical(other.sampleName, sampleName) || other.sampleName == sampleName)&&(identical(other.sampleBaseMidi, sampleBaseMidi) || other.sampleBaseMidi == sampleBaseMidi)&&(identical(other.isLoadingSample, isLoadingSample) || other.isLoadingSample == isLoadingSample)&&const DeepCollectionEquality().equals(other._activePads, _activePads)&&const DeepCollectionEquality().equals(other._slicePoints, _slicePoints)&&const DeepCollectionEquality().equals(other._sliceNotes, _sliceNotes)&&(identical(other.pitched, pitched) || other.pitched == pitched));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sampleWavBytes),sampleName,sampleBaseMidi,isLoadingSample,const DeepCollectionEquality().hash(_activePads),const DeepCollectionEquality().hash(_slicePoints),const DeepCollectionEquality().hash(_sliceNotes),pitched);

@override
String toString() {
  return 'PlayState(sampleWavBytes: $sampleWavBytes, sampleName: $sampleName, sampleBaseMidi: $sampleBaseMidi, isLoadingSample: $isLoadingSample, activePads: $activePads, slicePoints: $slicePoints, sliceNotes: $sliceNotes, pitched: $pitched)';
}


}

/// @nodoc
abstract mixin class _$PlayStateCopyWith<$Res> implements $PlayStateCopyWith<$Res> {
  factory _$PlayStateCopyWith(_PlayState value, $Res Function(_PlayState) _then) = __$PlayStateCopyWithImpl;
@override @useResult
$Res call({
 Uint8List? sampleWavBytes, String sampleName, int sampleBaseMidi, bool isLoadingSample, Set<int> activePads, List<double> slicePoints, List<int> sliceNotes, bool pitched
});




}
/// @nodoc
class __$PlayStateCopyWithImpl<$Res>
    implements _$PlayStateCopyWith<$Res> {
  __$PlayStateCopyWithImpl(this._self, this._then);

  final _PlayState _self;
  final $Res Function(_PlayState) _then;

/// Create a copy of PlayState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sampleWavBytes = freezed,Object? sampleName = null,Object? sampleBaseMidi = null,Object? isLoadingSample = null,Object? activePads = null,Object? slicePoints = null,Object? sliceNotes = null,Object? pitched = null,}) {
  return _then(_PlayState(
sampleWavBytes: freezed == sampleWavBytes ? _self.sampleWavBytes : sampleWavBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,sampleName: null == sampleName ? _self.sampleName : sampleName // ignore: cast_nullable_to_non_nullable
as String,sampleBaseMidi: null == sampleBaseMidi ? _self.sampleBaseMidi : sampleBaseMidi // ignore: cast_nullable_to_non_nullable
as int,isLoadingSample: null == isLoadingSample ? _self.isLoadingSample : isLoadingSample // ignore: cast_nullable_to_non_nullable
as bool,activePads: null == activePads ? _self._activePads : activePads // ignore: cast_nullable_to_non_nullable
as Set<int>,slicePoints: null == slicePoints ? _self._slicePoints : slicePoints // ignore: cast_nullable_to_non_nullable
as List<double>,sliceNotes: null == sliceNotes ? _self._sliceNotes : sliceNotes // ignore: cast_nullable_to_non_nullable
as List<int>,pitched: null == pitched ? _self.pitched : pitched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
