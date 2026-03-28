import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_sample.dart';

part 'saved_samples_state.freezed.dart';

@freezed
abstract class SavedSamplesState with _$SavedSamplesState {
  const factory SavedSamplesState({
    @Default([]) List<SavedSample> userSamples,
    @Default([]) List<SavedSample> starredSamples,
    @Default([]) List<SavedSample> publicSamples,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SavedSamplesState;
}
