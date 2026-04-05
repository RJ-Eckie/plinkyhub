import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_pack.dart';

part 'saved_packs_state.freezed.dart';

@freezed
abstract class SavedPacksState with _$SavedPacksState {
  const factory SavedPacksState({
    @Default([]) List<SavedPack> userPacks,
    @Default([]) List<SavedPack> starredPacks,
    @Default([]) List<SavedPack> publicPacks,
    @Default(false) bool isLoading,
    @Default(false) bool hasLoadedUserItems,
    @Default(false) bool hasLoadedPublicItems,
    String? errorMessage,
    SavedPack? editingPack,
  }) = _SavedPacksState;
}
