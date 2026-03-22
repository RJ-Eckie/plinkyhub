import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_sample.freezed.dart';
part 'saved_sample.g.dart';

@freezed
abstract class SavedSample with _$SavedSample {
  const factory SavedSample({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'file_path') required String filePath,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @Default('') String description,
    @Default(false) @JsonKey(name: 'is_public') bool isPublic,
  }) = _SavedSample;

  factory SavedSample.fromJson(Map<String, dynamic> json) =>
      _$SavedSampleFromJson(json);
}
