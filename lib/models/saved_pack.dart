import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/pack_slot.dart';

part 'saved_pack.freezed.dart';
part 'saved_pack.g.dart';

@freezed
abstract class SavedPack with _$SavedPack {
  const factory SavedPack({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
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
    @Default([]) @JsonKey(name: 'pack_slots') List<PackSlot> slots,
  }) = _SavedPack;

  factory SavedPack.fromJson(Map<String, dynamic> json) =>
      _$SavedPackFromJson(json);
}

Object? _readUsername(Map<dynamic, dynamic> json, String key) {
  final profiles = json['profiles'];
  if (profiles is Map<String, dynamic>) {
    return profiles['username'];
  }
  return json[key];
}

Object? _readStarCount(Map<dynamic, dynamic> json, String key) {
  final starsList = json['pack_stars'];
  if (starsList is List && starsList.isNotEmpty) {
    final first = starsList.first;
    if (first is Map<String, dynamic>) {
      return first['count'];
    }
  }
  return json[key];
}
