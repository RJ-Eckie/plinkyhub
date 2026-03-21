// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_patch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedPatch {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name; String get category;@JsonKey(name: 'patch_data') String get patchData;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt; String get description;@JsonKey(name: 'is_public') bool get isPublic;
/// Create a copy of SavedPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedPatchCopyWith<SavedPatch> get copyWith => _$SavedPatchCopyWithImpl<SavedPatch>(this as SavedPatch, _$identity);

  /// Serializes this SavedPatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedPatch&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.patchData, patchData) || other.patchData == patchData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,category,patchData,createdAt,updatedAt,description,isPublic);

@override
String toString() {
  return 'SavedPatch(id: $id, userId: $userId, name: $name, category: $category, patchData: $patchData, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $SavedPatchCopyWith<$Res>  {
  factory $SavedPatchCopyWith(SavedPatch value, $Res Function(SavedPatch) _then) = _$SavedPatchCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String category,@JsonKey(name: 'patch_data') String patchData,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String description,@JsonKey(name: 'is_public') bool isPublic
});




}
/// @nodoc
class _$SavedPatchCopyWithImpl<$Res>
    implements $SavedPatchCopyWith<$Res> {
  _$SavedPatchCopyWithImpl(this._self, this._then);

  final SavedPatch _self;
  final $Res Function(SavedPatch) _then;

/// Create a copy of SavedPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? category = null,Object? patchData = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isPublic = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,patchData: null == patchData ? _self.patchData : patchData // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedPatch].
extension SavedPatchPatterns on SavedPatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedPatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedPatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedPatch value)  $default,){
final _that = this;
switch (_that) {
case _SavedPatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedPatch value)?  $default,){
final _that = this;
switch (_that) {
case _SavedPatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String category, @JsonKey(name: 'patch_data')  String patchData, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedPatch() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.category,_that.patchData,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String category, @JsonKey(name: 'patch_data')  String patchData, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic)  $default,) {final _that = this;
switch (_that) {
case _SavedPatch():
return $default(_that.id,_that.userId,_that.name,_that.category,_that.patchData,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String category, @JsonKey(name: 'patch_data')  String patchData, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt,  String description, @JsonKey(name: 'is_public')  bool isPublic)?  $default,) {final _that = this;
switch (_that) {
case _SavedPatch() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.category,_that.patchData,_that.createdAt,_that.updatedAt,_that.description,_that.isPublic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedPatch implements SavedPatch {
  const _SavedPatch({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, required this.category, @JsonKey(name: 'patch_data') required this.patchData, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, this.description = '', @JsonKey(name: 'is_public') this.isPublic = false});
  factory _SavedPatch.fromJson(Map<String, dynamic> json) => _$SavedPatchFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override final  String category;
@override@JsonKey(name: 'patch_data') final  String patchData;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'is_public') final  bool isPublic;

/// Create a copy of SavedPatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedPatchCopyWith<_SavedPatch> get copyWith => __$SavedPatchCopyWithImpl<_SavedPatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedPatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedPatch&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.patchData, patchData) || other.patchData == patchData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,category,patchData,createdAt,updatedAt,description,isPublic);

@override
String toString() {
  return 'SavedPatch(id: $id, userId: $userId, name: $name, category: $category, patchData: $patchData, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class _$SavedPatchCopyWith<$Res> implements $SavedPatchCopyWith<$Res> {
  factory _$SavedPatchCopyWith(_SavedPatch value, $Res Function(_SavedPatch) _then) = __$SavedPatchCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String category,@JsonKey(name: 'patch_data') String patchData,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt, String description,@JsonKey(name: 'is_public') bool isPublic
});




}
/// @nodoc
class __$SavedPatchCopyWithImpl<$Res>
    implements _$SavedPatchCopyWith<$Res> {
  __$SavedPatchCopyWithImpl(this._self, this._then);

  final _SavedPatch _self;
  final $Res Function(_SavedPatch) _then;

/// Create a copy of SavedPatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? category = null,Object? patchData = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isPublic = null,}) {
  return _then(_SavedPatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,patchData: null == patchData ? _self.patchData : patchData // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
