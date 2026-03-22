// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_bank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedBank _$SavedBankFromJson(Map<String, dynamic> json) => _SavedBank(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  description: json['description'] as String? ?? '',
  isPublic: json['is_public'] as bool? ?? false,
  slots:
      (json['bank_slots'] as List<dynamic>?)
          ?.map((e) => BankSlot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SavedBankToJson(_SavedBank instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'description': instance.description,
      'is_public': instance.isPublic,
      'bank_slots': instance.slots,
    };
