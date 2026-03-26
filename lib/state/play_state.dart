import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'play_state.freezed.dart';

@freezed
abstract class PlayState with _$PlayState {
  const factory PlayState({
    Uint8List? sampleWavBytes,
    @Default('') String sampleName,
    @Default(60) int sampleBaseMidi,
    @Default(false) bool isLoadingSample,
    @Default({}) Set<int> activePads,
  }) = _PlayState;
}
