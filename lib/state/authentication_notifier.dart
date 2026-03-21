import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/authentication_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authenticationProvider =
    NotifierProvider<AuthenticationNotifier, AuthenticationState>(
  AuthenticationNotifier.new,
);

class AuthenticationNotifier extends Notifier<AuthenticationState> {
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  AuthenticationState build() {
    final currentUser = _supabase.auth.currentUser;
    _authSubscription?.cancel();
    _authSubscription =
        _supabase.auth.onAuthStateChange.listen((authState) {
      state = state.copyWith(
        user: authState.session?.user,
        isLoading: false,
        errorMessage: null,
      );
    });
    ref.onDispose(() => _authSubscription?.cancel());
    return AuthenticationState(user: currentUser);
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.auth.signOut();
      state = const AuthenticationState();
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
