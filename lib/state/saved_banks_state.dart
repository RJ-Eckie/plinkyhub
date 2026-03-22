import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/saved_bank.dart';

part 'saved_banks_state.freezed.dart';

@freezed
abstract class SavedBanksState with _$SavedBanksState {
  const factory SavedBanksState({
    @Default([]) List<SavedBank> userBanks,
    @Default([]) List<SavedBank> publicBanks,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SavedBanksState;
}
