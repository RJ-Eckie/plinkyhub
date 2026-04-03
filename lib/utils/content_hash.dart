import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Computes a SHA-256 hex digest of the given binary data.
String computeContentHash(Uint8List data) {
  return sha256.convert(data).toString();
}

/// Computes a deterministic SHA-256 hash for a pack based on all its
/// content hashes. The hash is stable regardless of the order items
/// were parsed — preset and pattern hashes are sorted by slot/index
/// and sample hashes by slot index.
///
/// The wavetable hash is intentionally excluded because the wavetable
/// only appears on the emulated drive when transferred in the same session.
String computePackContentHash({
  required Map<int, String> presetHashes,
  required Map<int, String> sampleHashes,
  required Map<int, String> patternHashes,
}) {
  final parts = <String>[];

  // Presets sorted by slot index.
  final presetKeys = presetHashes.keys.toList()..sort();
  for (final key in presetKeys) {
    parts.add('p$key:${presetHashes[key]}');
  }

  // Samples sorted by slot index.
  final sampleKeys = sampleHashes.keys.toList()..sort();
  for (final key in sampleKeys) {
    parts.add('s$key:${sampleHashes[key]}');
  }

  // Patterns sorted by pattern index.
  final patternKeys = patternHashes.keys.toList()..sort();
  for (final key in patternKeys) {
    parts.add('t$key:${patternHashes[key]}');
  }

  final combined = utf8.encode(parts.join('|'));
  return sha256.convert(combined).toString();
}
