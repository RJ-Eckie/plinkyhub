import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_dump.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/dumps_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dumpsProvider = NotifierProvider<DumpsNotifier, DumpsState>(
  DumpsNotifier.new,
);

class DumpsNotifier extends Notifier<DumpsState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  DumpsState build() {
    final user = ref.watch(
      authenticationProvider.select((authState) => authState.user),
    );
    if (user != null) {
      Future.microtask(fetchDumps);
    }
    return const DumpsState();
  }

  Future<void> fetchDumps() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      state = state.copyWith(dumps: const []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('dumps')
          .select('*, profiles(username)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final dumps = (response as List)
          .map((row) => SavedDump.fromJson(row as Map<String, dynamic>))
          .toList();
      state = state.copyWith(dumps: dumps, isLoading: false);
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Uploads a dump (internal and external flash bytes) to Supabase.
  /// Returns the created [SavedDump].
  Future<SavedDump?> uploadDump({
    required String title,
    required String description,
    required Uint8List internalFlashBytes,
    required Uint8List externalFlashBytes,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return null;
    }

    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch.toRadixString(
      36,
    );
    final internalPath = '$userId/${uniqueSuffix}_int.bin';
    final externalPath = '$userId/${uniqueSuffix}_ext.bin';

    await _supabase.storage
        .from('dumps')
        .uploadBinary(internalPath, internalFlashBytes);
    await _supabase.storage
        .from('dumps')
        .uploadBinary(externalPath, externalFlashBytes);

    final inserted = await _supabase
        .from('dumps')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'internal_flash_path': internalPath,
          'external_flash_path': externalPath,
          'internal_flash_size': internalFlashBytes.length,
          'external_flash_size': externalFlashBytes.length,
        })
        .select('*, profiles(username)')
        .single();

    final dump = SavedDump.fromJson(inserted);
    state = state.copyWith(dumps: [dump, ...state.dumps]);
    return dump;
  }

  Future<void> deleteDump(SavedDump dump) async {
    try {
      await _supabase.storage.from('dumps').remove([
        dump.internalFlashPath,
        dump.externalFlashPath,
      ]);
      await _supabase.from('dumps').delete().eq('id', dump.id);
      state = state.copyWith(
        dumps: state.dumps.where((entry) => entry.id != dump.id).toList(),
      );
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<Uint8List> downloadFlash({required String filePath}) async {
    return _supabase.storage.from('dumps').download(filePath);
  }
}
