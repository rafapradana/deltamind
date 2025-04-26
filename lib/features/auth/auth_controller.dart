import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth state for the application
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for auth state
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// Auth controller for managing authentication
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState()) {
    // Initialize the auth state with the current user
    final currentUser = SupabaseService.currentUser;
    state = state.copyWith(user: currentUser);
    
    // Listen for auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
        state = state.copyWith(user: session?.user);
      } else if (event == AuthChangeEvent.signedOut) {
        state = state.copyWith(user: null);
      }
    }, onError: (error) {
      debugPrint('Auth state change error: $error');
    });
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.user != null;

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await SupabaseService.signInWithEmailAndPassword(
        email,
        password,
      );
      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await SupabaseService.signUpWithEmailAndPassword(
        email,
        password,
      );
      
      // Create user profile
      if (response.user != null) {
        await SupabaseService.createUserProfile(
          userId: response.user!.id,
          email: email,
          username: username,
        );
      }
      
      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.signInWithGoogle();
      // Note: Auth state will be updated by the onAuthStateChange listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.signOut();
      state = state.copyWith(
        user: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
} 