import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_firmware.dart';

part 'firmwares_state.freezed.dart';

@freezed
abstract class FirmwaresState with _$FirmwaresState {
  const factory FirmwaresState({
    @Default([]) List<SavedFirmware> firmwares,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _FirmwaresState;
}
