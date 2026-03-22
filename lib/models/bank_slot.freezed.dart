// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BankSlot {

 String get id;@JsonKey(name: 'bank_id') String get bankId;@JsonKey(name: 'slot_number') int get slotNumber;@JsonKey(name: 'patch_id') String? get patchId;@JsonKey(name: 'sample_id') String? get sampleId;
/// Create a copy of BankSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankSlotCopyWith<BankSlot> get copyWith => _$BankSlotCopyWithImpl<BankSlot>(this as BankSlot, _$identity);

  /// Serializes this BankSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.slotNumber, slotNumber) || other.slotNumber == slotNumber)&&(identical(other.patchId, patchId) || other.patchId == patchId)&&(identical(other.sampleId, sampleId) || other.sampleId == sampleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankId,slotNumber,patchId,sampleId);

@override
String toString() {
  return 'BankSlot(id: $id, bankId: $bankId, slotNumber: $slotNumber, patchId: $patchId, sampleId: $sampleId)';
}


}

/// @nodoc
abstract mixin class $BankSlotCopyWith<$Res>  {
  factory $BankSlotCopyWith(BankSlot value, $Res Function(BankSlot) _then) = _$BankSlotCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'bank_id') String bankId,@JsonKey(name: 'slot_number') int slotNumber,@JsonKey(name: 'patch_id') String? patchId,@JsonKey(name: 'sample_id') String? sampleId
});




}
/// @nodoc
class _$BankSlotCopyWithImpl<$Res>
    implements $BankSlotCopyWith<$Res> {
  _$BankSlotCopyWithImpl(this._self, this._then);

  final BankSlot _self;
  final $Res Function(BankSlot) _then;

/// Create a copy of BankSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankId = null,Object? slotNumber = null,Object? patchId = freezed,Object? sampleId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,slotNumber: null == slotNumber ? _self.slotNumber : slotNumber // ignore: cast_nullable_to_non_nullable
as int,patchId: freezed == patchId ? _self.patchId : patchId // ignore: cast_nullable_to_non_nullable
as String?,sampleId: freezed == sampleId ? _self.sampleId : sampleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BankSlot].
extension BankSlotPatterns on BankSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankSlot value)  $default,){
final _that = this;
switch (_that) {
case _BankSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankSlot value)?  $default,){
final _that = this;
switch (_that) {
case _BankSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'slot_number')  int slotNumber, @JsonKey(name: 'patch_id')  String? patchId, @JsonKey(name: 'sample_id')  String? sampleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankSlot() when $default != null:
return $default(_that.id,_that.bankId,_that.slotNumber,_that.patchId,_that.sampleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'slot_number')  int slotNumber, @JsonKey(name: 'patch_id')  String? patchId, @JsonKey(name: 'sample_id')  String? sampleId)  $default,) {final _that = this;
switch (_that) {
case _BankSlot():
return $default(_that.id,_that.bankId,_that.slotNumber,_that.patchId,_that.sampleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'slot_number')  int slotNumber, @JsonKey(name: 'patch_id')  String? patchId, @JsonKey(name: 'sample_id')  String? sampleId)?  $default,) {final _that = this;
switch (_that) {
case _BankSlot() when $default != null:
return $default(_that.id,_that.bankId,_that.slotNumber,_that.patchId,_that.sampleId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BankSlot implements BankSlot {
  const _BankSlot({required this.id, @JsonKey(name: 'bank_id') required this.bankId, @JsonKey(name: 'slot_number') required this.slotNumber, @JsonKey(name: 'patch_id') this.patchId, @JsonKey(name: 'sample_id') this.sampleId});
  factory _BankSlot.fromJson(Map<String, dynamic> json) => _$BankSlotFromJson(json);

@override final  String id;
@override@JsonKey(name: 'bank_id') final  String bankId;
@override@JsonKey(name: 'slot_number') final  int slotNumber;
@override@JsonKey(name: 'patch_id') final  String? patchId;
@override@JsonKey(name: 'sample_id') final  String? sampleId;

/// Create a copy of BankSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankSlotCopyWith<_BankSlot> get copyWith => __$BankSlotCopyWithImpl<_BankSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.slotNumber, slotNumber) || other.slotNumber == slotNumber)&&(identical(other.patchId, patchId) || other.patchId == patchId)&&(identical(other.sampleId, sampleId) || other.sampleId == sampleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankId,slotNumber,patchId,sampleId);

@override
String toString() {
  return 'BankSlot(id: $id, bankId: $bankId, slotNumber: $slotNumber, patchId: $patchId, sampleId: $sampleId)';
}


}

/// @nodoc
abstract mixin class _$BankSlotCopyWith<$Res> implements $BankSlotCopyWith<$Res> {
  factory _$BankSlotCopyWith(_BankSlot value, $Res Function(_BankSlot) _then) = __$BankSlotCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'bank_id') String bankId,@JsonKey(name: 'slot_number') int slotNumber,@JsonKey(name: 'patch_id') String? patchId,@JsonKey(name: 'sample_id') String? sampleId
});




}
/// @nodoc
class __$BankSlotCopyWithImpl<$Res>
    implements _$BankSlotCopyWith<$Res> {
  __$BankSlotCopyWithImpl(this._self, this._then);

  final _BankSlot _self;
  final $Res Function(_BankSlot) _then;

/// Create a copy of BankSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankId = null,Object? slotNumber = null,Object? patchId = freezed,Object? sampleId = freezed,}) {
  return _then(_BankSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,slotNumber: null == slotNumber ? _self.slotNumber : slotNumber // ignore: cast_nullable_to_non_nullable
as int,patchId: freezed == patchId ? _self.patchId : patchId // ignore: cast_nullable_to_non_nullable
as String?,sampleId: freezed == sampleId ? _self.sampleId : sampleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
