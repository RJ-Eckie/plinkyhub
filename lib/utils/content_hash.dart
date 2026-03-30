import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Computes a SHA-256 hex digest of the given binary data.
String computeContentHash(Uint8List data) {
  return sha256.convert(data).toString();
}
