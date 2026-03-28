import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';

part 'saved_wavetables_state.freezed.dart';

@freezed
abstract class SavedWavetablesState with _$SavedWavetablesState {
  const factory SavedWavetablesState({
    @Default([]) List<SavedWavetable> userWavetables,
    @Default([]) List<SavedWavetable> publicWavetables,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SavedWavetablesState;
}
