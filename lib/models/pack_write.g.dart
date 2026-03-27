// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_write.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PackWrite _$PackWriteFromJson(Map<String, dynamic> json) => _PackWrite(
  userId: json['user_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  isPublic: json['is_public'] as bool? ?? false,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PackWriteToJson(_PackWrite instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'is_public': instance.isPublic,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
