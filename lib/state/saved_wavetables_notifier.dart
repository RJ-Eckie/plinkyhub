import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/models/wavetable_write.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_wavetables_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final savedWavetablesProvider =
    NotifierProvider<SavedWavetablesNotifier, SavedWavetablesState>(
      SavedWavetablesNotifier.new,
    );

class SavedWavetablesNotifier extends Notifier<SavedWavetablesState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  SavedWavetablesState build() {
    final authenticationState = ref.watch(authenticationProvider);
    if (authenticationState.user != null) {
      Future.microtask(fetchUserWavetables);
    }
    return const SavedWavetablesState();
  }

  Future<Set<String>> _fetchStarredWavetableIds() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return {};
    }
    final stars = await _supabase
        .from('wavetable_stars')
        .select('wavetable_id')
        .eq('user_id', userId);
    return {
      for (final row in stars as List)
        (row as Map<String, dynamic>)['wavetable_id'] as String,
    };
  }

  List<SavedWavetable> _applyStarred(
    List<dynamic> response,
    Set<String> starredIds,
  ) {
    return response.map((row) {
      final map = row as Map<String, dynamic>;
      return SavedWavetable.fromJson(map).copyWith(
        isStarred: starredIds.contains(map['id']),
      );
    }).toList();
  }

  Future<void> fetchUserWavetables() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('wavetables')
          .select('*, profiles(username), wavetable_stars(count)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final starredIds = await _fetchStarredWavetableIds();
      final wavetables = _applyStarred(response as List, starredIds);

      state = state.copyWith(userWavetables: wavetables, isLoading: false);
      await fetchStarredWavetables();
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> fetchStarredWavetables() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    try {
      final starredIds = await _fetchStarredWavetableIds();
      if (starredIds.isEmpty) {
        state = state.copyWith(starredWavetables: []);
        return;
      }

      final response = await _supabase
          .from('wavetables')
          .select(
            '*, profiles(username), wavetable_stars(count)',
          )
          .inFilter('id', starredIds.toList())
          .neq('user_id', userId);

      final wavetables = _applyStarred(response as List, starredIds);
      state = state.copyWith(starredWavetables: wavetables);
    } on Exception catch (error) {
      debugPrint('$error');
    }
  }

  Future<void> fetchPublicWavetables() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('wavetables')
          .select('*, profiles(username), wavetable_stars(count)')
          .eq('is_public', true);

      final starredIds = await _fetchStarredWavetableIds();
      final wavetables = _applyStarred(response as List, starredIds);
      state = state.copyWith(publicWavetables: wavetables, isLoading: false);
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> saveWavetable(
    SavedWavetable wavetable, {
    required Uint8List uf2Bytes,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.storage
          .from('wavetables')
          .uploadBinary(
            wavetable.filePath,
            uf2Bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final write = WavetableWrite(
        userId: wavetable.userId,
        name: wavetable.name,
        filePath: wavetable.filePath,
        description: wavetable.description,
        isPublic: wavetable.isPublic,
      );
      await _supabase.from('wavetables').insert(write.toJson());

      await fetchUserWavetables();
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateWavetable(SavedWavetable wavetable) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final write = WavetableWrite(
        userId: wavetable.userId,
        name: wavetable.name,
        filePath: wavetable.filePath,
        description: wavetable.description,
        isPublic: wavetable.isPublic,
      );
      await _supabase
          .from('wavetables')
          .update(write.toJson())
          .eq('id', wavetable.id);
      await fetchUserWavetables();
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<Uint8List> downloadUf2(String filePath) async {
    return _supabase.storage.from('wavetables').download(filePath);
  }

  Future<void> deleteWavetable(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final wavetable = state.userWavetables
          .where((w) => w.id == id)
          .firstOrNull;
      if (wavetable != null) {
        await _supabase.storage.from('wavetables').remove([
          wavetable.filePath,
        ]);
      }
      await _supabase.from('wavetables').delete().eq('id', id);
      await fetchUserWavetables();
      await fetchPublicWavetables();
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> toggleStar(SavedWavetable wavetable) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    try {
      if (wavetable.isStarred) {
        await _supabase
            .from('wavetable_stars')
            .delete()
            .eq('wavetable_id', wavetable.id)
            .eq('user_id', userId);
      } else {
        await _supabase.from('wavetable_stars').insert({
          'wavetable_id': wavetable.id,
          'user_id': userId,
        });
      }

      final delta = wavetable.isStarred ? -1 : 1;
      final newIsStarred = !wavetable.isStarred;
      final updatedStarred = newIsStarred
          ? [
              ...state.starredWavetables,
              if (wavetable.userId != userId)
                wavetable.copyWith(
                  isStarred: true,
                  starCount: wavetable.starCount + delta,
                ),
            ]
          : state.starredWavetables.where((w) => w.id != wavetable.id).toList();
      state = state.copyWith(
        userWavetables: _updateStarInList(
          state.userWavetables,
          wavetable.id,
          newIsStarred,
          delta,
        ),
        starredWavetables: updatedStarred,
        publicWavetables: _updateStarInList(
          state.publicWavetables,
          wavetable.id,
          newIsStarred,
          delta,
        ),
      );
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  List<SavedWavetable> _updateStarInList(
    List<SavedWavetable> wavetables,
    String wavetableId,
    bool isStarred,
    int delta,
  ) {
    return wavetables.map((w) {
      if (w.id == wavetableId) {
        return w.copyWith(
          isStarred: isStarred,
          starCount: w.starCount + delta,
        );
      }
      return w;
    }).toList();
  }
}
