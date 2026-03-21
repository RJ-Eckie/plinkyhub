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
  }) = _SavedPatch;

  factory SavedPatch.fromJson(Map<String, dynamic> json) =>
      _$SavedPatchFromJson(json);
}
