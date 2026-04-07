import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/models/saved_pack.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';

/// View state for the My Plinky page.
enum MyPlinkyPageState { connect, loading, loaded, error }

/// A linked-entry triple stored per preset slot.
typedef LinkedSlot = ({String? presetId, String? sampleId, String? patternId});

class MyPlinkyState {
  const MyPlinkyState({
    this.pageState = MyPlinkyPageState.connect,
    this.statusMessage = '',
    this.progress,
    this.errorMessage,
    this.includeSamples = true,
    this.samplesLoaded = false,
    this.directory,
    this.parsedFlashImage,
    this.devicePresets = const {},
    this.deviceSampleSlots = const {},
    this.slots = const [],
    this.wavetableId,
    this.patternIds = const {},
    this.deviceHasWavetable = false,
    this.devicePatternIndices = const [],
    this.matchedPack,
  });

  final MyPlinkyPageState pageState;
  final String statusMessage;
  final double? progress;
  final String? errorMessage;
  final bool includeSamples;
  final bool samplesLoaded;

  final FileSystemDirectoryHandle? directory;
  final ParsedFlashImage? parsedFlashImage;

  final Map<int, Preset> devicePresets;
  final Set<int> deviceSampleSlots;
  final List<LinkedSlot> slots;
  final String? wavetableId;
  final Map<int, String?> patternIds;
  final bool deviceHasWavetable;
  final List<int> devicePatternIndices;
  final SavedPack? matchedPack;

  MyPlinkyState copyWith({
    MyPlinkyPageState? pageState,
    String? statusMessage,
    double? Function()? progress,
    String? Function()? errorMessage,
    bool? includeSamples,
    bool? samplesLoaded,
    FileSystemDirectoryHandle? Function()? directory,
    ParsedFlashImage? Function()? parsedFlashImage,
    Map<int, Preset>? devicePresets,
    Set<int>? deviceSampleSlots,
    List<LinkedSlot>? slots,
    String? Function()? wavetableId,
    Map<int, String?>? patternIds,
    bool? deviceHasWavetable,
    List<int>? devicePatternIndices,
    SavedPack? Function()? matchedPack,
  }) {
    return MyPlinkyState(
      pageState: pageState ?? this.pageState,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress != null ? progress() : this.progress,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      includeSamples: includeSamples ?? this.includeSamples,
      samplesLoaded: samplesLoaded ?? this.samplesLoaded,
      directory: directory != null ? directory() : this.directory,
      parsedFlashImage: parsedFlashImage != null
          ? parsedFlashImage()
          : this.parsedFlashImage,
      devicePresets: devicePresets ?? this.devicePresets,
      deviceSampleSlots: deviceSampleSlots ?? this.deviceSampleSlots,
      slots: slots ?? this.slots,
      wavetableId: wavetableId != null ? wavetableId() : this.wavetableId,
      patternIds: patternIds ?? this.patternIds,
      deviceHasWavetable: deviceHasWavetable ?? this.deviceHasWavetable,
      devicePatternIndices: devicePatternIndices ?? this.devicePatternIndices,
      matchedPack: matchedPack != null ? matchedPack() : this.matchedPack,
    );
  }
}
