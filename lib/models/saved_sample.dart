import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_sample.freezed.dart';
part 'saved_sample.g.dart';

const defaultSlicePoints = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875];

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
    @Default(defaultSlicePoints)
    @JsonKey(name: 'slice_points')
    List<double> slicePoints,
    @Default(60) @JsonKey(name: 'base_note') int baseNote,
    @Default(0) @JsonKey(name: 'fine_tune') int fineTune,
  }) = _SavedSample;

  factory SavedSample.fromJson(Map<String, dynamic> json) =>
      _$SavedSampleFromJson(json);
}
