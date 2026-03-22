import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_bank.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_banks_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final savedBanksProvider =
    NotifierProvider<SavedBanksNotifier, SavedBanksState>(
  SavedBanksNotifier.new,
);

class SavedBanksNotifier extends Notifier<SavedBanksState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  SavedBanksState build() {
    final authenticationState = ref.watch(authenticationProvider);
    if (authenticationState.user != null) {
      Future.microtask(fetchUserBanks);
    }
    return const SavedBanksState();
  }

  Future<void> fetchUserBanks() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('banks')
          .select('*, bank_slots(*)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final banks = (response as List).map((row) {
        return SavedBank.fromJson(row as Map<String, dynamic>);
      }).toList();

      state = state.copyWith(userBanks: banks, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> fetchPublicBanks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = ref.read(authenticationProvider).user?.id;
      var query = _supabase
          .from('banks')
          .select('*, bank_slots(*)')
          .eq('is_public', true);

      if (userId != null) {
        query = query.neq('user_id', userId);
      }

      final response = await query.order('updated_at', ascending: false);

      final banks = (response as List).map((row) {
        return SavedBank.fromJson(row as Map<String, dynamic>);
      }).toList();

      state = state.copyWith(publicBanks: banks, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> saveBank(
    String name, {
    required List<({int slotNumber, String? patchId, String? sampleId})> slots,
    String description = '',
    bool isPublic = false,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bankResponse = await _supabase
          .from('banks')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'is_public': isPublic,
          })
          .select('id')
          .single();

      final bankId = bankResponse['id'] as String;

      final slotRows = slots
          .where((slot) => slot.patchId != null || slot.sampleId != null)
          .map((slot) => {
                'bank_id': bankId,
                'slot_number': slot.slotNumber,
                'patch_id': slot.patchId,
                'sample_id': slot.sampleId,
              })
          .toList();

      if (slotRows.isNotEmpty) {
        await _supabase.from('bank_slots').insert(slotRows);
      }

      await fetchUserBanks();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> updateBank(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) {
        updates['name'] = name;
      }
      if (description != null) {
        updates['description'] = description;
      }
      if (isPublic != null) {
        updates['is_public'] = isPublic;
      }

      await _supabase.from('banks').update(updates).eq('id', id);
      await fetchUserBanks();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteBank(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.from('banks').delete().eq('id', id);
      await fetchUserBanks();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
