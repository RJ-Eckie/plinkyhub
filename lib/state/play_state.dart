import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_sample.dart';

part 'play_state.freezed.dart';

@freezed
abstract class PlayState with _$PlayState {
  const factory PlayState({
    Uint8List? sampleWavBytes,
    @Default('') String sampleName,
    @Default(60) int sampleBaseMidi,
    @Default(false) bool isLoadingSample,
    @Default({}) Set<int> activePads,
    @Default(defaultSlicePoints) List<double> slicePoints,
    @Default(defaultSliceNotes) List<int> sliceNotes,
    @Default(false) bool pitched,
  }) = _PlayState;
}
