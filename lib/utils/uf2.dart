import 'dart:typed_data';

/// Base addresses for each Plinky sample slot (0-7).
const sampleSlotAddresses = [
  0x40000000, // SAMPLE0
  0x40400000, // SAMPLE1
  0x40800000, // SAMPLE2
  0x40C00000, // SAMPLE3
  0x41000000, // SAMPLE4
  0x41400000, // SAMPLE5
  0x41800000, // SAMPLE6
  0x41C00000, // SAMPLE7
];

/// Maximum sample size per slot (8 MB).
const maxSampleSize = 8 * 1024 * 1024;

/// UF2 magic numbers.
const magic1 = 0x0A324655;
const magic2 = 0x9E5D5157;
const magicEnd = 0x0AB16F30;

/// Bytes of payload data per UF2 block.
const dataPerBlock = 256;

/// Total size of one UF2 block.
const uf2BlockSize = 512;

/// Converts raw [data] into a UF2 file targeting [baseAddress].
///
/// Each UF2 block carries [dataPerBlock] bytes of payload at incrementing
/// addresses starting from [baseAddress].
Uint8List dataToUf2(Uint8List data, int baseAddress) {
  final totalBlocks = (data.length + dataPerBlock - 1) ~/ dataPerBlock;
  final output = ByteData(totalBlocks * uf2BlockSize);

  for (var blockNum = 0; blockNum < totalBlocks; blockNum++) {
    final offset = blockNum * uf2BlockSize;
    final dataOffset = blockNum * dataPerBlock;
    final dataLength = (dataOffset + dataPerBlock <= data.length)
        ? dataPerBlock
        : data.length - dataOffset;

    // Header
    output.setUint32(offset + 0, magic1, Endian.little);
    output.setUint32(offset + 4, magic2, Endian.little);
    output.setUint32(offset + 8, 0x00000000, Endian.little); // flags
    output.setUint32(
      offset + 12,
      baseAddress + dataOffset,
      Endian.little,
    ); // target address
    output.setUint32(offset + 16, dataLength, Endian.little);
    output.setUint32(offset + 20, blockNum, Endian.little);
    output.setUint32(offset + 24, totalBlocks, Endian.little);
    output.setUint32(offset + 28, 0, Endian.little); // reserved / family ID

    // Data payload (remaining bytes in the 476-byte region are already zero)
    for (var i = 0; i < dataLength; i++) {
      output.setUint8(offset + 32 + i, data[dataOffset + i]);
    }

    // Final magic
    output.setUint32(offset + uf2BlockSize - 4, magicEnd, Endian.little);
  }

  return output.buffer.asUint8List();
}

/// Converts raw sample [data] into a UF2 file targeting the given [slotIndex]
/// (0-7) in Plinky's sample memory.
///
/// Returns the UF2 file as bytes ready to be saved or flashed to a Plinky.
Uint8List sampleToUf2(Uint8List data, {int slotIndex = 0}) {
  assert(slotIndex >= 0 && slotIndex < 8, 'slotIndex must be 0-7');
  assert(data.length <= maxSampleSize, 'Sample exceeds 8 MB limit');

  return dataToUf2(data, sampleSlotAddresses[slotIndex]);
}

/// Returns the UF2 file path for a given original sample [filePath].
///
/// Example: `userId/sample.wav` → `userId/sample.uf2`
String uf2PathFromFilePath(String filePath) {
  final lastDot = filePath.lastIndexOf('.');
  if (lastDot == -1) {
    return '$filePath.uf2';
  }
  return '${filePath.substring(0, lastDot)}.uf2';
}
