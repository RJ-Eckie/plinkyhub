import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_firmware.freezed.dart';
part 'saved_firmware.g.dart';

@freezed
abstract class SavedFirmware with _$SavedFirmware {
  const factory SavedFirmware({
    required String id,
    required String userId,
    required String name,
    required String version,
    required String filePath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('') String description,
    @Default(false) bool isBeta,
    @Default(false) bool isPinned,
  }) = _SavedFirmware;

  factory SavedFirmware.fromJson(Map<String, dynamic> json) =>
      _$SavedFirmwareFromJson(json);
}
