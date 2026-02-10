import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(firebaseServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirebaseService _firebaseService;

  AuthNotifier(this._firebaseService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _firebaseService.auth.authStateChanges().listen((user) async {
      print('[DEBUG] Auth state changed: ${user?.uid}');
      if (user == null) {
        print('[DEBUG] User signed out');
        state = const AsyncValue.data(null);
        return;
      }
      try {
        print('[DEBUG] Getting user data for: ${user.uid}');
        final userModel = await _firebaseService.getUser(user.uid);
        if (userModel != null) {
          print('[DEBUG] User data loaded: ${userModel.name}');
          state = AsyncValue.data(userModel);
        } else {
          print('[DEBUG] User data not found');
          state = const AsyncValue.data(null);
        }
      } catch (e, st) {
        print('[ERROR] Failed to get user data: $e');
        state = AsyncValue.error(e, st);
      }
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      state = const AsyncValue.loading();
      final credential = await _firebaseService.signUp(email, password);
      
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        gender: '', // Will be set in profile setup
        birthday: DateTime.now(), // Will be set in profile setup
        createdAt: DateTime.now(),
        interestedIn: 'all', // Default value
        ageRange: [18, 100], // Default value
        maxDistance: 50, // Default value
        interests: [], // Default empty list
        heightRange: [150, 200], // Default height range
      );

      await _firebaseService.createUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.signIn(email, password);
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.signInWithGoogle();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.signInWithApple();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> linkCredentialToExistingAccount({
    required String email,
    required String password,
    required AuthCredential credential,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.linkCredentialToExistingAccount(
        email: email,
        password: password,
        credential: credential,
      );
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAccount({String? password}) async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.deleteAccount(password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      state = const AsyncValue.loading();
      await _firebaseService.updateUser(user);
      final updatedUser = await _firebaseService.getUser(user.id);
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Refresh user data from Firestore (e.g. after location update).
  Future<void> refreshUser() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final updated = await _firebaseService.getUser(current.id);
      if (updated != null) state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
} 