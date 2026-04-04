import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_firmware.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/firmwares_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final firmwaresProvider = NotifierProvider<FirmwaresNotifier, FirmwaresState>(
  FirmwaresNotifier.new,
);

class FirmwaresNotifier extends Notifier<FirmwaresState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  FirmwaresState build() {
    Future.microtask(fetchFirmwares);
    return const FirmwaresState();
  }

  Future<void> fetchFirmwares() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('firmwares')
          .select()
          .order('created_at', ascending: false);
      final firmwares = (response as List)
          .map(
            (row) => SavedFirmware.fromJson(row as Map<String, dynamic>),
          )
          .toList();
      state = state.copyWith(firmwares: firmwares, isLoading: false);
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> uploadFirmware({
    required String name,
    required String version,
    required String description,
    required bool isBeta,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    final storagePath = '$userId/$fileName';
    await _supabase.storage
        .from('firmwares')
        .uploadBinary(storagePath, fileBytes);

    await _supabase.from('firmwares').insert({
      'user_id': userId,
      'name': name,
      'version': version,
      'description': description,
      'is_beta': isBeta,
      'file_path': storagePath,
    });

    await fetchFirmwares();
  }

  Future<void> deleteFirmware(String id, String filePath) async {
    try {
      await _supabase.storage.from('firmwares').remove([filePath]);
      await _supabase.from('firmwares').delete().eq('id', id);
      await fetchFirmwares();
    } on Exception catch (error) {
      debugPrint('$error');
      state = state.copyWith(errorMessage: error.toString());
    }
  }
}
