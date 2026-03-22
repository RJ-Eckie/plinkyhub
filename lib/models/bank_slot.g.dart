// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BankSlot _$BankSlotFromJson(Map<String, dynamic> json) => _BankSlot(
  id: json['id'] as String,
  bankId: json['bank_id'] as String,
  slotNumber: (json['slot_number'] as num).toInt(),
  patchId: json['patch_id'] as String?,
  sampleId: json['sample_id'] as String?,
);

Map<String, dynamic> _$BankSlotToJson(_BankSlot instance) => <String, dynamic>{
  'id': instance.id,
  'bank_id': instance.bankId,
  'slot_number': instance.slotNumber,
  'patch_id': instance.patchId,
  'sample_id': instance.sampleId,
};
