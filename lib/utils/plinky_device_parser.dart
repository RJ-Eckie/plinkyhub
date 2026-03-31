import 'dart:typed_data';

import 'package:plinkyhub/utils/content_hash.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';

/// Input data for [parsePlinkyDevice], containing the raw file bytes
/// read from a Plinky in Tunnel of Lights mode.
class PlinkyDeviceInput {
  PlinkyDeviceInput({
    required this.presetsUf2,
    required this.sampleUf2s,
    this.wavetableBytes,
  });

  /// Raw PRESETS.UF2 bytes.
  final Uint8List presetsUf2;

  /// Raw SAMPLE0-7.UF2 bytes (null entries for missing files).
  final List<Uint8List?> sampleUf2s;

  /// Raw WAVETAB.UF2 bytes (null if missing).
  final Uint8List? wavetableBytes;
}

/// Parsed result from [parsePlinkyDevice], containing all device data
/// and precomputed content hashes.
class ParsedPlinkyDevice {
  ParsedPlinkyDevice({
    required this.presets,
    required this.sampleInfos,
    required this.rawSampleInfos,
    required this.patternQuarters,
    required this.nonEmptyPatternIndices,
    required this.samplePcmData,
    required this.emptySampleSlots,
    required this.presetHashes,
    required this.sampleHashes,
    required this.wavetableHash,
    required this.patternHashes,
    required this.deviceHasWavetable,
  });

  /// 32 preset byte arrays (null for empty slots).
  final List<Uint8List?> presets;

  /// 8 parsed sample info entries (null for empty slots).
  final List<ParsedSampleInfo?> sampleInfos;

  /// 8 raw sample info byte arrays (null for empty slots).
  final List<Uint8List?> rawSampleInfos;

  /// 96 pattern quarter entries.
  final List<Uint8List?> patternQuarters;

  /// Indices of patterns that have data.
  final List<int> nonEmptyPatternIndices;

  /// Trimmed, non-silent PCM data per sample slot index.
  final Map<int, Uint8List> samplePcmData;

  /// Sample slots that are empty or silent.
  final Set<int> emptySampleSlots;

  /// Content hashes for non-empty presets (slot index -> hash).
  final Map<int, String> presetHashes;

  /// Content hashes for non-silent samples (slot index -> hash).
  final Map<int, String> sampleHashes;

  /// Content hash for the wavetable (null if no wavetable).
  final String? wavetableHash;

  /// Content hashes for non-empty patterns (pattern index -> hash).
  final Map<int, String> patternHashes;

  /// Whether the device has a non-empty wavetable.
  final bool deviceHasWavetable;
}

/// Parses all data from a Plinky device. This is a top-level function
/// so it can be called via `Isolate.run` to keep the UI responsive.
///
/// Performs UF2 decoding, flash image parsing, PCM trimming, silence
/// detection, and SHA-256 content hashing for all items.
ParsedPlinkyDevice parsePlinkyDevice(PlinkyDeviceInput input) {
  // Parse PRESETS.UF2.
  final flashImage = uf2ToData(input.presetsUf2);
  final parsed = parseFlashImage(flashImage);

  // Compute preset hashes.
  final presetHashes = <int, String>{};
  for (var i = 0; i < presetCount; i++) {
    final presetBytes = parsed.presets[i];
    if (presetBytes != null) {
      // Check if preset is empty (all zero parameters).
      final allZero = presetBytes.every((b) => b == 0);
      if (!allZero) {
        presetHashes[i] = computeContentHash(presetBytes);
      }
    }
  }

  // Parse samples: decode UF2, trim, detect silence, hash.
  final samplePcmData = <int, Uint8List>{};
  final emptySampleSlots = <int>{};
  final sampleHashes = <int, String>{};

  for (var i = 0; i < sampleCount; i++) {
    final sampleUf2 = input.sampleUf2s[i];
    if (sampleUf2 == null || sampleUf2.isEmpty) {
      emptySampleSlots.add(i);
      continue;
    }
    try {
      var pcmData = uf2ToData(sampleUf2);
      final sampleInfo =
          i < parsed.sampleInfos.length ? parsed.sampleInfos[i] : null;
      if (sampleInfo != null &&
          sampleInfo.sampleLength * 2 < pcmData.length) {
        pcmData = Uint8List.sublistView(
          pcmData,
          0,
          sampleInfo.sampleLength * 2,
        );
      }
      if (pcmData.isNotEmpty && !_isSilentPcm(pcmData)) {
        samplePcmData[i] = pcmData;
        sampleHashes[i] = computeContentHash(pcmData);
      } else {
        emptySampleSlots.add(i);
      }
    } on FormatException {
      emptySampleSlots.add(i);
    }
  }

  // Check wavetable.
  final wavetableBytes = input.wavetableBytes;
  final deviceHasWavetable = wavetableBytes != null &&
      wavetableBytes.isNotEmpty &&
      !wavetableBytes.every((b) => b == 0) &&
      !wavetableBytes.every((b) => b == 0xFF);
  final wavetableHash =
      deviceHasWavetable ? computeContentHash(wavetableBytes) : null;

  // Compute pattern hashes.
  final patternHashes = <int, String>{};
  final nonEmptyPatternIndices = parsed.nonEmptyPatternIndices;
  for (final patternIndex in nonEmptyPatternIndices) {
    final quarterStart = patternIndex * 4;
    final quarters = List<Uint8List?>.filled(
      parsed.patternQuarters.length,
      null,
    );
    for (var q = 0; q < 4; q++) {
      final index = quarterStart + q;
      if (index < parsed.patternQuarters.length) {
        quarters[index] = parsed.patternQuarters[index];
      }
    }
    final patternBlob = serializePatternQuarters(quarters);
    patternHashes[patternIndex] = computeContentHash(patternBlob);
  }

  return ParsedPlinkyDevice(
    presets: parsed.presets,
    sampleInfos: parsed.sampleInfos,
    rawSampleInfos: parsed.rawSampleInfos,
    patternQuarters: parsed.patternQuarters,
    nonEmptyPatternIndices: nonEmptyPatternIndices,
    samplePcmData: samplePcmData,
    emptySampleSlots: emptySampleSlots,
    presetHashes: presetHashes,
    sampleHashes: sampleHashes,
    wavetableHash: wavetableHash,
    patternHashes: patternHashes,
    deviceHasWavetable: deviceHasWavetable,
  );
}

/// Returns true if the PCM data is silent (all zeros, all 0xFF,
/// or every 16-bit sample is the same value).
bool _isSilentPcm(Uint8List pcmData) {
  if (pcmData.isEmpty) {
    return true;
  }
  // Single pass: check if all bytes are the same value.
  final first = pcmData[0];
  for (var i = 1; i < pcmData.length; i++) {
    if (pcmData[i] != first) {
      // Bytes differ, but could still be uniform 16-bit samples.
      // Fall through to the 16-bit check.
      if (pcmData.length >= 4) {
        final view = Int16List.view(pcmData.buffer);
        final firstSample = view[0];
        for (var j = 1; j < view.length; j++) {
          if (view[j] != firstSample) {
            return false;
          }
        }
        return true;
      }
      return false;
    }
  }
  // All bytes identical (covers all-zero and all-0xFF).
  return true;
}
