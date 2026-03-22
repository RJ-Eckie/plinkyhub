# Plinky UF2 Format

## Overview

Plinky uses the UF2 format for storing presets, waveforms, and samples in flash memory. UF2 blocks
are saved to Plinky memory based entirely on the **target address field** in each block. Each
block's address should be 256 bytes beyond the previous block's address.

## Memory Map

| File        | Start Address | Size    |
| ----------- | ------------- | ------- |
| CURRENT UF2 | `0x08010000`  | 896 KB  |
| PRESETS UF2 | `0x08080000`  | 1020 KB |
| CALIB UF2   | `0x080FF800`  | 4 KB    |
| SAMPLE0 UF2 | `0x40000000`  | 8 MB    |
| SAMPLE1 UF2 | `0x40400000`  | 8 MB    |
| SAMPLE2 UF2 | `0x40800000`  | 8 MB    |
| SAMPLE3 UF2 | `0x40C00000`  | 8 MB    |
| SAMPLE4 UF2 | `0x41000000`  | 8 MB    |
| SAMPLE5 UF2 | `0x41400000`  | 8 MB    |
| SAMPLE6 UF2 | `0x41800000`  | 8 MB    |
| SAMPLE7 UF2 | `0x41C00000`  | 8 MB    |

## Samples

Sample UF2 files contain only the raw audio data. The metadata for each sample is stored separately
in the Presets file as a `SampleInfo` structure. Without this metadata, Plinky will not recognize
the sample and it will not have a waveform. For audio not recorded on Plinky, you must generate the
`SampleInfo` data yourself and place it correctly in the Presets file.

## Presets

The Presets file contains presets, sequences, and `SampleInfo` structures. The pages inside the
Presets file use flash wear leveling, which means they do not appear at predictable memory
locations. You must create `SampleInfo` entries with the correct properties for Plinky to retrieve
them.
