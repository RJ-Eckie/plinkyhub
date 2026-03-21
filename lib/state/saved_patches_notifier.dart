import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/patch.dart';
import 'package:plinkyhub/models/saved_patch.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/saved_patches_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final savedPatchesProvider =
    NotifierProvider<SavedPatchesNotifier, SavedPatchesState>(
  SavedPatchesNotifier.new,
);

class SavedPatchesNotifier extends Notifier<SavedPatchesState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  SavedPatchesState build() {
    final authenticationState = ref.watch(authenticationProvider);
    if (authenticationState.user != null) {
      Future.microtask(fetchUserPatches);
    }
    return const SavedPatchesState();
  }

  Future<void> fetchUserPatches() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('patches')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final patches =
          (response as List).map((row) {
            return SavedPatch.fromJson(row as Map<String, dynamic>);
          }).toList();

      state = state.copyWith(userPatches: patches, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> fetchPublicPatches() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = ref.read(authenticationProvider).user?.id;
      var query = _supabase
          .from('patches')
          .select()
          .eq('is_public', true);

      // Exclude own patches from community list.
      if (userId != null) {
        query = query.neq('user_id', userId);
      }

      final response = await query.order('updated_at', ascending: false);

      final patches =
          (response as List).map((row) {
            return SavedPatch.fromJson(row as Map<String, dynamic>);
          }).toList();

      state = state.copyWith(publicPatches: patches, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> savePatch(
    Patch patch, {
    String description = '',
    bool isPublic = false,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final patchData = base64Encode(Uint8List.view(patch.buffer));
      await _supabase.from('patches').insert({
        'user_id': userId,
        'name': patch.name,
        'category': patch.category.name,
        'patch_data': patchData,
        'description': description,
        'is_public': isPublic,
      });

      await fetchUserPatches();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> updatePatch(
    String id, {
    String? description,
    bool? isPublic,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (description != null) {
        updates['description'] = description;
      }
      if (isPublic != null) {
        updates['is_public'] = isPublic;
      }

      await _supabase.from('patches').update(updates).eq('id', id);
      await fetchUserPatches();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deletePatch(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.from('patches').delete().eq('id', id);
      await fetchUserPatches();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void loadPatchIntoEditor(SavedPatch savedPatch) {
    final bytes = base64Decode(savedPatch.patchData);
    ref
        .read(plinkyProvider.notifier)
        .loadPatchFromBytes(Uint8List.fromList(bytes));
  }
}
