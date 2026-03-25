import 'dart:math';
import 'dart:typed_data';

/// Plinky's native sample rate.
const plinkySampleRate = 31250;

/// Maximum number of PCM frames that fit in one Plinky sample slot.
const maxPcmFrames = 2097152;

/// Maximum raw PCM size in bytes for one Plinky sample slot.
const maxPcmBytes = maxPcmFrames * 2;

/// Parses a WAV file and converts the audio to Plinky's native format:
/// 16-bit signed, mono, little-endian, 31,250 Hz.
///
/// Throws [FormatException] if the file is not a valid PCM WAV.
Uint8List wavToPlinkyPcm(Uint8List wavBytes) {
  final data = ByteData.sublistView(wavBytes);
  var offset = 0;

  // RIFF header
  if (_readFourCC(data, offset) != 'RIFF') {
    throw const FormatException('Not a WAV file: missing RIFF header');
  }
  offset += 4;
  offset += 4; // file size
  if (_readFourCC(data, offset) != 'WAVE') {
    throw const FormatException('Not a WAV file: missing WAVE identifier');
  }
  offset += 4;

  // Find fmt and data chunks
  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  Uint8List? rawData;

  while (offset < data.lengthInBytes - 8) {
    final chunkId = _readFourCC(data, offset);
    final chunkSize = data.getUint32(offset + 4, Endian.little);
    offset += 8;

    if (chunkId == 'fmt ') {
      final audioFormat = data.getUint16(offset, Endian.little);
      if (audioFormat != 1) {
        throw const FormatException(
          'Only uncompressed PCM WAV files are supported',
        );
      }
      channels = data.getUint16(offset + 2, Endian.little);
      sampleRate = data.getUint32(offset + 4, Endian.little);
      // skip byte rate (4) and block align (2)
      bitsPerSample = data.getUint16(offset + 14, Endian.little);
    } else if (chunkId == 'data') {
      rawData = wavBytes.sublist(offset, offset + chunkSize);
    }

    offset += chunkSize;
    // Chunks are word-aligned
    if (chunkSize.isOdd) {
      offset += 1;
    }
  }

  if (channels == null || sampleRate == null || bitsPerSample == null) {
    throw const FormatException('WAV file missing fmt chunk');
  }
  if (rawData == null) {
    throw const FormatException('WAV file missing data chunk');
  }

  // Decode samples to double (-1.0 to 1.0)
  final samples = _decodeSamples(rawData, channels, bitsPerSample);

  // Resample to Plinky's native rate
  final resampled = _resample(samples, sampleRate, plinkySampleRate);

  // Encode as 16-bit signed little-endian
  return _encodePcm16(resampled);
}

/// Decodes raw PCM bytes into mono floating-point samples normalized to
/// -1.0..1.0.
List<double> _decodeSamples(Uint8List raw, int channels, int bitsPerSample) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final frameSize = bytesPerSample * channels;
  final frameCount = raw.length ~/ frameSize;
  final data = ByteData.sublistView(raw);
  final samples = List<double>.filled(frameCount, 0);

  for (var i = 0; i < frameCount; i++) {
    var sum = 0.0;
    for (var ch = 0; ch < channels; ch++) {
      final byteOffset = i * frameSize + ch * bytesPerSample;
      sum += _readSample(data, byteOffset, bitsPerSample);
    }
    samples[i] = sum / channels;
  }

  return samples;
}

/// Reads a single sample from [data] at [offset] and returns it normalized
/// to -1.0..1.0.
double _readSample(ByteData data, int offset, int bitsPerSample) {
  switch (bitsPerSample) {
    case 8:
      // 8-bit WAV is unsigned
      return (data.getUint8(offset) - 128) / 128.0;
    case 16:
      return data.getInt16(offset, Endian.little) / 32768.0;
    case 24:
      final b0 = data.getUint8(offset);
      final b1 = data.getUint8(offset + 1);
      final b2 = data.getInt8(offset + 2);
      final value = b0 | (b1 << 8) | (b2 << 16);
      return value / 8388608.0;
    case 32:
      return data.getInt32(offset, Endian.little) / 2147483648.0;
    default:
      throw FormatException('Unsupported bit depth: $bitsPerSample');
  }
}

/// Resamples [samples] from [srcRate] to [dstRate] using linear
/// interpolation.
List<double> _resample(List<double> samples, int srcRate, int dstRate) {
  if (srcRate == dstRate) {
    return samples;
  }

  final ratio = srcRate / dstRate;
  final outputLength = (samples.length / ratio).floor();
  final output = List<double>.filled(outputLength, 0);

  for (var i = 0; i < outputLength; i++) {
    final srcPos = i * ratio;
    final index = srcPos.floor();
    final frac = srcPos - index;

    if (index + 1 < samples.length) {
      output[i] = samples[index] * (1 - frac) + samples[index + 1] * frac;
    } else {
      output[i] = samples[min(index, samples.length - 1)];
    }
  }

  return output;
}

/// Encodes floating-point samples to 16-bit signed little-endian PCM.
Uint8List _encodePcm16(List<double> samples) {
  final output = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final value = (clamped * 32767).round();
    output.setInt16(i * 2, value, Endian.little);
  }
  return output.buffer.asUint8List();
}

String _readFourCC(ByteData data, int offset) {
  return String.fromCharCodes([
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ]);
}
