import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_patch.dart';

part 'saved_patches_state.freezed.dart';

@freezed
abstract class SavedPatchesState with _$SavedPatchesState {
  const factory SavedPatchesState({
    @Default([]) List<SavedPatch> userPatches,
    @Default([]) List<SavedPatch> publicPatches,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SavedPatchesState;
}
