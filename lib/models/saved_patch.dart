import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_patch.freezed.dart';
part 'saved_patch.g.dart';

@freezed
abstract class SavedPatch with _$SavedPatch {
  const factory SavedPatch({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    required String category,
    @JsonKey(name: 'patch_data') required String patchData,
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
  }) = _SavedPatch;

  factory SavedPatch.fromJson(Map<String, dynamic> json) =>
      _$SavedPatchFromJson(json);
}

Object? _readUsername(Map<dynamic, dynamic> json, String key) {
  final profiles = json['profiles'];
  if (profiles is Map<String, dynamic>) {
    return profiles['username'];
  }
  return json[key];
}

Object? _readStarCount(Map<dynamic, dynamic> json, String key) {
  final starsList = json['patch_stars'];
  if (starsList is List && starsList.isNotEmpty) {
    final first = starsList.first;
    if (first is Map<String, dynamic>) {
      return first['count'];
    }
  }
  return json[key];
}
