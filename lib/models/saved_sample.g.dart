// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedSample _$SavedSampleFromJson(Map<String, dynamic> json) => _SavedSample(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  filePath: json['file_path'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  description: json['description'] as String? ?? '',
  isPublic: json['is_public'] as bool? ?? false,
);

Map<String, dynamic> _$SavedSampleToJson(_SavedSample instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'file_path': instance.filePath,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'description': instance.description,
      'is_public': instance.isPublic,
    };
