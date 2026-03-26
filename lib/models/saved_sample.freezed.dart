// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_sample.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedSample {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name;@JsonKey(name: 'file_path') String get filePath;@JsonKey(name: 'pcm_file_path') String get pcmFilePath;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; String get description;@JsonKey(name: 'is_public') bool get isPublic;@JsonKey(readValue: _readUsername) String get username;@JsonKey(name: 'star_count', readValue: _readStarCount) int get starCount;@JsonKey(name: 'is_starred') bool get isStarred;@JsonKey(name: 'slice_points') List<double> get slicePoints;@JsonKey(name: 'base_note') int get baseNote;@JsonKey(name: 'fine_tune') int get fineTune; bool get pitched;@JsonKey(name: 'slice_notes') List<int> get sliceNotes;
/// Create a copy of SavedSample
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedSampleCopyWith<SavedSample> get copyWith => _$SavedSampleCopyWithImpl<SavedSample>(this as SavedSample, _$identity);

  /// Serializes this SavedSample to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedSample&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.pcmFilePath, pcmFilePath) || other.pcmFilePath == pcmFilePath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.username, username) || other.username == username)&&(identical(other.starCount, starCount) || other.starCount == starCount)&&(identical(other.isStarred, isStarred) || other.isStarred == isStarred)&&const DeepCollectionEquality().equals(other.slicePoints, slicePoints)&&(identical(other.baseNote, baseNote) || other.baseNote == baseNote)&&(identical(other.fineTune, fineTune) || other.fineTune == fineTune)&&(identical(other.pitched, pitched) || other.pitched == pitched)&&const DeepCollectionEquality().equals(other.sliceNotes, sliceNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,filePath,pcmFilePath,createdAt,updatedAt,description,isPublic,username,starCount,isStarred,const DeepCollectionEquality().hash(slicePoints),baseNote,fineTune,pitched,const DeepCollectionEquality().hash(sliceNotes));

@override
String toString() {
  return 'SavedSample(id: $id, userId: $userId, name: $name, filePath: $filePath, pcmFilePath: $pcmFilePath, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isPublic: $isPublic, username: $username, starCount: $starCount, isStarred: $isStarred, slicePoints: $slicePoints, baseNote: $baseNote, fineTune: $fineTune, pitched: $pitched, sliceNotes: $sliceNotes)';
}


}

/// @nodoc
abstract mixin class $SavedSampleCopyWith<$Res>  {
  factory $SavedSampleCopyWith(SavedSample value, $Res Function(SavedSample) _then) = _$SavedSampleCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'file_path') String filePath,@JsonKey(name: 'pcm_file_path') String pcmFilePath,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String description,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(readValue: _readUsername) String username,@JsonKey(name: 'star_count', readValue: _readStarCount) int starCount,@JsonKey(name: 'is_starred') bool isStarred,@JsonKey(name: 'slice_points') List<double> slicePoints,@JsonKey(name: 'base_note') int baseNote,@JsonKey(name: 'fine_tune') int fineTune, bool pitched,@JsonKey(name: 'slice_notes') List<int> sliceNotes
});




}
/// @nodoc
class _$SavedSampleCopyWithImpl<$Res>
    implements $SavedSampleCopyWith<$Res> {
  _$SavedSampleCopyWithImpl(this._self, this._then);

  final SavedSample _self;
  final $Res Function(SavedSample) _then;

/// Create a copy of SavedSample
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? filePath = null,Object? pcmFilePath = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isPublic = null,Object? username = null,Object? starCount = null,Object? isStarred = null,Object? slicePoints = null,Object? baseNote = null,Object? fineTune = null,Object? pitched = null,Object? sliceNotes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,pcmFilePath: null == pcmFilePath ? _self.pcmFilePath : pcmFilePath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,isStarred: null == isStarred ? _self.isStarred : isStarred // ignore: cast_nullable_to_non_nullable
as bool,slicePoints: null == slicePoints ? _self.slicePoints : slicePoints // ignore: cast_nullable_to_non_nullable
as List<double>,baseNote: null == baseNote ? _self.baseNote : baseNote // ignore: cast_nullable_to_non_nullable
as int,fineTune: null == fineTune ? _self.fineTune : fineTune // ignore: cast_nullable_to_non_nullable
as int,pitched: null == pitched ? _self.pitched : pitched // ignore: cast_nullable_to_non_nullable
as bool,sliceNotes: null == sliceNotes ? _self.sliceNotes : sliceNotes // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedSample].
extension SavedSamplePatterns on SavedSample {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedSample value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedSample() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedSample value)  $default,){
final _that = this;
switch (_that) {
case _SavedSample():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedSample value)?  $default,){
final _that = this;
switch (_that) {
case _SavedSample() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'file_path')  String filePath, @JsonKey(name: 'pcm_file_path')  String pcmFilePath, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(readValue: _readUsername)  String username, @JsonKey(name: 'star_count', readValue: _readStarCount)  int starCount, @JsonKey(name: 'is_starred')  bool isStarred, @JsonKey(name: 'slice_points')  List<double> slicePoints, @JsonKey(name: 'base_note')  int baseNote, @JsonKey(name: 'fine_tune')  int fineTune,  bool pitched, @JsonKey(name: 'slice_notes')  List<int> sliceNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedSample() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.filePath,_that.pcmFilePath,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic,_that.username,_that.starCount,_that.isStarred,_that.slicePoints,_that.baseNote,_that.fineTune,_that.pitched,_that.sliceNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'file_path')  String filePath, @JsonKey(name: 'pcm_file_path')  String pcmFilePath, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(readValue: _readUsername)  String username, @JsonKey(name: 'star_count', readValue: _readStarCount)  int starCount, @JsonKey(name: 'is_starred')  bool isStarred, @JsonKey(name: 'slice_points')  List<double> slicePoints, @JsonKey(name: 'base_note')  int baseNote, @JsonKey(name: 'fine_tune')  int fineTune,  bool pitched, @JsonKey(name: 'slice_notes')  List<int> sliceNotes)  $default,) {final _that = this;
switch (_that) {
case _SavedSample():
return $default(_that.id,_that.userId,_that.name,_that.filePath,_that.pcmFilePath,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic,_that.username,_that.starCount,_that.isStarred,_that.slicePoints,_that.baseNote,_that.fineTune,_that.pitched,_that.sliceNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'file_path')  String filePath, @JsonKey(name: 'pcm_file_path')  String pcmFilePath, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(readValue: _readUsername)  String username, @JsonKey(name: 'star_count', readValue: _readStarCount)  int starCount, @JsonKey(name: 'is_starred')  bool isStarred, @JsonKey(name: 'slice_points')  List<double> slicePoints, @JsonKey(name: 'base_note')  int baseNote, @JsonKey(name: 'fine_tune')  int fineTune,  bool pitched, @JsonKey(name: 'slice_notes')  List<int> sliceNotes)?  $default,) {final _that = this;
switch (_that) {
case _SavedSample() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.filePath,_that.pcmFilePath,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic,_that.username,_that.starCount,_that.isStarred,_that.slicePoints,_that.baseNote,_that.fineTune,_that.pitched,_that.sliceNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedSample implements SavedSample {
  const _SavedSample({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, @JsonKey(name: 'file_path') required this.filePath, @JsonKey(name: 'pcm_file_path') required this.pcmFilePath, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.description = '', @JsonKey(name: 'is_public') this.isPublic = false, @JsonKey(readValue: _readUsername) this.username = '', @JsonKey(name: 'star_count', readValue: _readStarCount) this.starCount = 0, @JsonKey(name: 'is_starred') this.isStarred = false, @JsonKey(name: 'slice_points') final  List<double> slicePoints = defaultSlicePoints, @JsonKey(name: 'base_note') this.baseNote = 60, @JsonKey(name: 'fine_tune') this.fineTune = 0, this.pitched = false, @JsonKey(name: 'slice_notes') final  List<int> sliceNotes = defaultSliceNotes}): _slicePoints = slicePoints,_sliceNotes = sliceNotes;
  factory _SavedSample.fromJson(Map<String, dynamic> json) => _$SavedSampleFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override@JsonKey(name: 'file_path') final  String filePath;
@override@JsonKey(name: 'pcm_file_path') final  String pcmFilePath;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'is_public') final  bool isPublic;
@override@JsonKey(readValue: _readUsername) final  String username;
@override@JsonKey(name: 'star_count', readValue: _readStarCount) final  int starCount;
@override@JsonKey(name: 'is_starred') final  bool isStarred;
 final  List<double> _slicePoints;
@override@JsonKey(name: 'slice_points') List<double> get slicePoints {
  if (_slicePoints is EqualUnmodifiableListView) return _slicePoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slicePoints);
}

@override@JsonKey(name: 'base_note') final  int baseNote;
@override@JsonKey(name: 'fine_tune') final  int fineTune;
@override@JsonKey() final  bool pitched;
 final  List<int> _sliceNotes;
@override@JsonKey(name: 'slice_notes') List<int> get sliceNotes {
  if (_sliceNotes is EqualUnmodifiableListView) return _sliceNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sliceNotes);
}


/// Create a copy of SavedSample
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedSampleCopyWith<_SavedSample> get copyWith => __$SavedSampleCopyWithImpl<_SavedSample>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedSampleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedSample&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.pcmFilePath, pcmFilePath) || other.pcmFilePath == pcmFilePath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.username, username) || other.username == username)&&(identical(other.starCount, starCount) || other.starCount == starCount)&&(identical(other.isStarred, isStarred) || other.isStarred == isStarred)&&const DeepCollectionEquality().equals(other._slicePoints, _slicePoints)&&(identical(other.baseNote, baseNote) || other.baseNote == baseNote)&&(identical(other.fineTune, fineTune) || other.fineTune == fineTune)&&(identical(other.pitched, pitched) || other.pitched == pitched)&&const DeepCollectionEquality().equals(other._sliceNotes, _sliceNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,filePath,pcmFilePath,createdAt,updatedAt,description,isPublic,username,starCount,isStarred,const DeepCollectionEquality().hash(_slicePoints),baseNote,fineTune,pitched,const DeepCollectionEquality().hash(_sliceNotes));

@override
String toString() {
  return 'SavedSample(id: $id, userId: $userId, name: $name, filePath: $filePath, pcmFilePath: $pcmFilePath, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isPublic: $isPublic, username: $username, starCount: $starCount, isStarred: $isStarred, slicePoints: $slicePoints, baseNote: $baseNote, fineTune: $fineTune, pitched: $pitched, sliceNotes: $sliceNotes)';
}


}

/// @nodoc
abstract mixin class _$SavedSampleCopyWith<$Res> implements $SavedSampleCopyWith<$Res> {
  factory _$SavedSampleCopyWith(_SavedSample value, $Res Function(_SavedSample) _then) = __$SavedSampleCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'file_path') String filePath,@JsonKey(name: 'pcm_file_path') String pcmFilePath,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String description,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(readValue: _readUsername) String username,@JsonKey(name: 'star_count', readValue: _readStarCount) int starCount,@JsonKey(name: 'is_starred') bool isStarred,@JsonKey(name: 'slice_points') List<double> slicePoints,@JsonKey(name: 'base_note') int baseNote,@JsonKey(name: 'fine_tune') int fineTune, bool pitched,@JsonKey(name: 'slice_notes') List<int> sliceNotes
});




}
/// @nodoc
class __$SavedSampleCopyWithImpl<$Res>
    implements _$SavedSampleCopyWith<$Res> {
  __$SavedSampleCopyWithImpl(this._self, this._then);

  final _SavedSample _self;
  final $Res Function(_SavedSample) _then;

/// Create a copy of SavedSample
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? filePath = null,Object? pcmFilePath = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isPublic = null,Object? username = null,Object? starCount = null,Object? isStarred = null,Object? slicePoints = null,Object? baseNote = null,Object? fineTune = null,Object? pitched = null,Object? sliceNotes = null,}) {
  return _then(_SavedSample(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,pcmFilePath: null == pcmFilePath ? _self.pcmFilePath : pcmFilePath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,starCount: null == starCount ? _self.starCount : starCount // ignore: cast_nullable_to_non_nullable
as int,isStarred: null == isStarred ? _self.isStarred : isStarred // ignore: cast_nullable_to_non_nullable
as bool,slicePoints: null == slicePoints ? _self._slicePoints : slicePoints // ignore: cast_nullable_to_non_nullable
as List<double>,baseNote: null == baseNote ? _self.baseNote : baseNote // ignore: cast_nullable_to_non_nullable
as int,fineTune: null == fineTune ? _self.fineTune : fineTune // ignore: cast_nullable_to_non_nullable
as int,pitched: null == pitched ? _self.pitched : pitched // ignore: cast_nullable_to_non_nullable
as bool,sliceNotes: null == sliceNotes ? _self._sliceNotes : sliceNotes // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
