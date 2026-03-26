import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_sample.freezed.dart';
part 'saved_sample.g.dart';

const defaultSlicePoints = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875];

/// Default slice notes: all set to 48 (C4 in Plinky's note scheme, which maps
/// to MIDI note 60).
const defaultSliceNotes = [48, 48, 48, 48, 48, 48, 48, 48];

@freezed
abstract class SavedSample with _$SavedSample {
  const factory SavedSample({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'file_path') required String filePath,
    @JsonKey(name: 'pcm_file_path') required String pcmFilePath,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @Default('') String description,
    @Default(false) @JsonKey(name: 'is_public') bool isPublic,
    @Default('')
    @JsonKey(readValue: _readUsername)
    String username,
    @Default(0)
    @JsonKey(name: 'star_count', readValue: _readStarCount)
    int starCount,
    @Default(false) @JsonKey(name: 'is_starred') bool isStarred,
    @Default(defaultSlicePoints)
    @JsonKey(name: 'slice_points')
    List<double> slicePoints,
    @Default(60) @JsonKey(name: 'base_note') int baseNote,
    @Default(0) @JsonKey(name: 'fine_tune') int fineTune,
    @Default(false) bool pitched,
    @Default(defaultSliceNotes)
    @JsonKey(name: 'slice_notes')
    List<int> sliceNotes,
  }) = _SavedSample;

  factory SavedSample.fromJson(Map<String, dynamic> json) =>
      _$SavedSampleFromJson(json);
}

Object? _readUsername(Map<dynamic, dynamic> json, String key) {
  final profiles = json['profiles'];
  if (profiles is Map<String, dynamic>) {
    return profiles['username'];
  }
  return json[key];
}

Object? _readStarCount(Map<dynamic, dynamic> json, String key) {
  final starsList = json['sample_stars'];
  if (starsList is List && starsList.isNotEmpty) {
    final first = starsList.first;
    if (first is Map<String, dynamic>) {
      return first['count'];
    }
  }
  return json[key];
}
