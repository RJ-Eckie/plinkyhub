import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_samples_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final savedSamplesProvider =
    NotifierProvider<SavedSamplesNotifier, SavedSamplesState>(
  SavedSamplesNotifier.new,
);

class SavedSamplesNotifier extends Notifier<SavedSamplesState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  SavedSamplesState build() {
    final authenticationState = ref.watch(authenticationProvider);
    if (authenticationState.user != null) {
      Future.microtask(fetchUserSamples);
    }
    return const SavedSamplesState();
  }

  Future<void> fetchUserSamples() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('samples')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final samples = (response as List).map((row) {
        return SavedSample.fromJson(row as Map<String, dynamic>);
      }).toList();

      state = state.copyWith(userSamples: samples, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> fetchPublicSamples() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = ref.read(authenticationProvider).user?.id;
      var query = _supabase
          .from('samples')
          .select()
          .eq('is_public', true);

      if (userId != null) {
        query = query.neq('user_id', userId);
      }

      final response = await query.order('updated_at', ascending: false);

      final samples = (response as List).map((row) {
        return SavedSample.fromJson(row as Map<String, dynamic>);
      }).toList();

      state = state.copyWith(publicSamples: samples, isLoading: false);
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> saveSample(
    String name,
    Uint8List fileBytes,
    String fileName, {
    String description = '',
    bool isPublic = false,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final filePath = '$userId/$fileName';
      await _supabase.storage.from('samples').uploadBinary(
        filePath,
        fileBytes,
      );

      await _supabase.from('samples').insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'is_public': isPublic,
        'file_path': filePath,
      });

      await fetchUserSamples();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> updateSample(
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

      await _supabase.from('samples').update(updates).eq('id', id);
      await fetchUserSamples();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteSample(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sample = state.userSamples.where((s) => s.id == id).firstOrNull;
      if (sample != null) {
        await _supabase.storage.from('samples').remove([sample.filePath]);
      }
      await _supabase.from('samples').delete().eq('id', id);
      await fetchUserSamples();
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
