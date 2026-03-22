import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_slot.freezed.dart';
part 'bank_slot.g.dart';

@freezed
abstract class BankSlot with _$BankSlot {
  const factory BankSlot({
    required String id,
    @JsonKey(name: 'bank_id') required String bankId,
    @JsonKey(name: 'slot_number') required int slotNumber,
    @JsonKey(name: 'patch_id') String? patchId,
    @JsonKey(name: 'sample_id') String? sampleId,
  }) = _BankSlot;

  factory BankSlot.fromJson(Map<String, dynamic> json) =>
      _$BankSlotFromJson(json);
}
