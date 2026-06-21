import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_failure.dart';
import 'package:clover/core/auth/models/user_model.dart';
import 'package:clover/core/session/account_session_cleanup.dart';
import 'package:clover/core/storage/account_storage_keys.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class AuthRepository {
  AuthRepository(
    this._supabase,
    this._storage,
    this._googleSignIn,
    this._sessionCleanup,
  );

  final SupabaseClient _supabase;
  final IAppStorage _storage;
  final GoogleSignIn _googleSignIn;
  final AccountSessionCleanup _sessionCleanup;

  Future<bool> isAuthenticated() async {
    if (_supabase.auth.currentSession != null) return true;

    final cachedUserId = await _storage.read<String>(key: AccountStorageKeys.authUserId);
    return cachedUserId != null && cachedUserId.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  /// Native Google Sign-In → idToken → Supabase (без Client Secret и без браузера).
  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }

    final account = await _googleSignIn.authenticate(scopeHint: const ['email', 'profile']);

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure(AuthErrorCode.googleIdTokenMissing);
    }

    final clientAuth = await account.authorizationClient.authorizationForScopes(const ['email', 'profile']);

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: clientAuth?.accessToken,
    );

    final user = response.user ?? _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
    }

    await _storage.write<String>(key: AccountStorageKeys.authUserId, value: user.id);
    return UserModel.fromSupabaseUser(user);
  }

  Future<void> signOut() async {
    await _sessionCleanup.clear();
    await _supabase.auth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
  }
}
