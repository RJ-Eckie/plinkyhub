import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plinkyhub/models/bank_slot.dart';

part 'saved_bank.freezed.dart';
part 'saved_bank.g.dart';

@freezed
abstract class SavedBank with _$SavedBank {
  const factory SavedBank({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @Default('') String description,
    @Default(false) @JsonKey(name: 'is_public') bool isPublic,
    @Default([]) @JsonKey(name: 'bank_slots') List<BankSlot> slots,
  }) = _SavedBank;

  factory SavedBank.fromJson(Map<String, dynamic> json) =>
      _$SavedBankFromJson(json);
}
