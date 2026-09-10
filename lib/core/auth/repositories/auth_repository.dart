import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_mapper.dart';
import 'package:clover/core/auth/errors/auth_failure.dart';
import 'package:clover/core/auth/models/user_model.dart';
import 'package:clover/core/push/app_push_messaging_service.dart';
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
    this._pushMessaging,
  );

  final SupabaseClient _supabase;
  final IAppStorage _storage;
  final GoogleSignIn _googleSignIn;
  final AccountSessionCleanup _sessionCleanup;
  final AppPushMessagingService _pushMessaging;

  static const minPasswordLength = 8;
  static const otpResendCooldownSeconds = 400;

  Future<bool> isAuthenticated() async {
    return ensureValidSession();
  }

  /// Запас до истечения access token: refresh только если близко к концу / уже истёк.
  static const _sessionRefreshSkew = Duration(seconds: 120);

  /// Проверяет сессию; при живом JWT — без сети; при `refresh_token_not_found` — локальный выход.
  Future<bool> ensureValidSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      final cachedUserId = await _storage.read<String>(key: AccountStorageKeys.authUserId);
      if (cachedUserId != null && cachedUserId.isNotEmpty) {
        await _sessionCleanup.clear();
      }
      return false;
    }

    if (!_needsSessionRefresh(session)) {
      return true;
    }

    try {
      await _supabase.auth.refreshSession();
      return _supabase.auth.currentSession != null;
    } on AuthException catch (error) {
      if (AuthErrorMapper.isInvalidRefreshToken(error)) {
        await forceLocalSignOut();
        return false;
      }
      if (!session.isExpired) return true;
      rethrow;
    }
  }

  bool _needsSessionRefresh(Session session) {
    if (session.isExpired) return true;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiresUtc = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiresUtc.subtract(_sessionRefreshSkew));
  }

  Future<void> clearLocalAccountData() async {
    await _sessionCleanup.clear();
  }

  Future<void> forceLocalSignOut() async {
    try {
      await _pushMessaging.detachForSignOut();
    } catch (_) {}
    await _sessionCleanup.clear();
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Stream<AuthChangeEvent> get authChangeEvents =>
      _supabase.auth.onAuthStateChange.map((state) => state.event);

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

    await _persistSession(user);
    return UserModel.fromSupabaseUser(user);
  }

  /// Login: ник или email + пароль.
  Future<UserModel> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    final email = await resolveLoginEmail(identifier);
    if (email == null || email.isEmpty) {
      throw const AuthFailure(AuthErrorCode.invalidCredentials);
    }
    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) {
      throw const AuthFailure(AuthErrorCode.invalidCredentials);
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: trimmedPassword,
      );
      final user = response.user ?? _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
      }
      await _persistSession(user);
      await _ensurePasswordSetMetadata(user);
      await _cacheHasPassword(user.id);
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  Future<String?> resolveLoginEmail(String identifier) async {
    final raw = identifier.trim();
    if (raw.isEmpty) {
      throw const AuthFailure(AuthErrorCode.identifierInvalid);
    }
    try {
      final result = await _supabase.rpc(
        'auth_resolve_login_email',
        params: {'p_identifier': raw},
      );
      final email = result?.toString().trim();
      if (email == null || email.isEmpty) return null;
      return email.toLowerCase();
    } catch (error) {
      if (raw.contains('@')) return raw.toLowerCase();
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    final trimmed = _normalizeEmail(email);
    _assertEmail(trimmed);
    try {
      final result = await _supabase.rpc(
        'auth_is_email_registered',
        params: {'p_email': trimmed},
      );
      return result == true;
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  /// Completed account (password or OAuth). Incomplete email OTP signup = false.
  Future<bool> isEmailFullyRegistered(String email) async {
    final trimmed = _normalizeEmail(email);
    _assertEmail(trimmed);
    try {
      final result = await _supabase.rpc(
        'auth_is_email_fully_registered',
        params: {'p_email': trimmed},
      );
      return result == true;
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  /// Register: OTP only if email is **not** a completed account.
  /// Incomplete OTP signup (user row without password/OAuth) may resend.
  Future<void> sendRegisterEmailOtp(String email) async {
    final trimmed = _normalizeEmail(email);
    _assertEmail(trimmed);

    if (await isEmailFullyRegistered(trimmed)) {
      throw const AuthFailure(AuthErrorCode.emailAlreadyRegistered);
    }

    await _claimEmailOtpSend(trimmed);

    try {
      await _supabase.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: true,
      );
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  /// True if `auth.users.encrypted_password` is set for the current session.
  ///
  /// Кэш: один раз узнали `true` → больше не ходим в RPC (пароль не «снимается»).
  /// Пока `false` — каждый раз спрашиваем бэк.
  Future<bool> currentUserHasPassword() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
    }

    final cacheKey = AccountStorageKeys.hasPassword(user.id);
    final cached = await _storage.read<bool>(key: cacheKey);
    if (cached == true) return true;

    try {
      final result = await _supabase.rpc('auth_current_user_has_password');
      final has = result == true;
      if (has) {
        await _storage.write<bool>(key: cacheKey, value: true);
      }
      return has;
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  Future<void> _cacheHasPassword(String userId) async {
    await _storage.write<bool>(key: AccountStorageKeys.hasPassword(userId), value: true);
  }

  /// Session email for OTP (settings reset). Null if user has no email.
  String? currentUserEmail() {
    final email = _supabase.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty || !email.contains('@')) return null;
    return email.toLowerCase();
  }

  /// Forgot password: OTP only if email **is** registered.
  Future<void> sendResetPasswordEmailOtp(String email) async {
    final trimmed = _normalizeEmail(email);
    _assertEmail(trimmed);

    if (!await isEmailRegistered(trimmed)) {
      throw const AuthFailure(AuthErrorCode.emailNotRegistered);
    }

    await _claimEmailOtpSend(trimmed);

    try {
      await _supabase.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: false,
      );
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  /// Seconds until this email may receive another OTP (backend + local cache).
  Future<int> emailOtpRetryAfterSeconds(String email) async {
    final trimmed = _normalizeEmail(email);
    if (trimmed.isEmpty || !trimmed.contains('@')) return 0;

    final localLeft = await _localOtpRetryAfter(trimmed);
    var remoteLeft = 0;
    try {
      final result = await _supabase.rpc(
        'auth_email_otp_retry_after',
        params: {
          'p_email': trimmed,
          'p_cooldown_seconds': otpResendCooldownSeconds,
        },
      );
      if (result is int) {
        remoteLeft = result;
      } else if (result is num) {
        remoteLeft = result.toInt();
      }
    } catch (_) {
      // UI / offline: опираемся на локальный кэш.
    }

    final left = localLeft > remoteLeft ? localLeft : remoteLeft;
    if (remoteLeft > localLeft) {
      await _syncLocalOtpCooldown(trimmed, remainingSeconds: remoteLeft);
    }
    return left < 0 ? 0 : left;
  }

  Future<void> _claimEmailOtpSend(String email) async {
    final localLeft = await _localOtpRetryAfter(email);
    if (localLeft > 0) {
      throw AuthFailure(
        AuthErrorCode.emailOtpRateLimited,
        retryAfterSeconds: localLeft,
      );
    }

    try {
      final result = await _supabase.rpc(
        'auth_claim_email_otp_send',
        params: {
          'p_email': email,
          'p_cooldown_seconds': otpResendCooldownSeconds,
        },
      );
      final wait = result is int
          ? result
          : result is num
              ? result.toInt()
              : 0;
      if (wait > 0) {
        await _syncLocalOtpCooldown(email, remainingSeconds: wait);
        throw AuthFailure(
          AuthErrorCode.emailOtpRateLimited,
          retryAfterSeconds: wait,
        );
      }
      await _writeLocalOtpSentNow(email);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      // RPC ещё не задеплоен / сеть: локальный кулдаун уже проверен выше.
      await _writeLocalOtpSentNow(email);
    }
  }

  Future<int> _localOtpRetryAfter(String email) async {
    final raw = await _storage.read<int>(key: AccountStorageKeys.otpCooldown(email));
    if (raw == null) return 0;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - raw;
    final leftMs = otpResendCooldownSeconds * 1000 - elapsedMs;
    if (leftMs <= 0) return 0;
    return (leftMs / 1000).ceil();
  }

  Future<void> _writeLocalOtpSentNow(String email) async {
    await _storage.write<int>(
      key: AccountStorageKeys.otpCooldown(email),
      value: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _syncLocalOtpCooldown(String email, {required int remainingSeconds}) async {
    final sentAt = DateTime.now().millisecondsSinceEpoch -
        ((otpResendCooldownSeconds - remainingSeconds) * 1000);
    await _storage.write<int>(
      key: AccountStorageKeys.otpCooldown(email),
      value: sentAt < 0 ? 0 : sentAt,
    );
  }

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final trimmedEmail = _normalizeEmail(email);
    final trimmedToken = token.trim();
    _assertEmail(trimmedEmail);
    if (trimmedToken.length < 4) {
      throw const AuthFailure(AuthErrorCode.emailOtpVerifyFailed);
    }

    try {
      final response = await _supabase.auth.verifyOTP(
        email: trimmedEmail,
        token: trimmedToken,
        type: OtpType.email,
      );

      final user = response.user ?? _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
      }

      await _persistSession(user);
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.resolve(error));
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure(AuthErrorMapper.resolve(error));
    }
  }

  Future<UserModel> setPassword(String password) async {
    final trimmed = password.trim();
    if (trimmed.length < minPasswordLength) {
      throw const AuthFailure(AuthErrorCode.passwordInvalid);
    }

    final current = _supabase.auth.currentUser;
    if (current == null) {
      throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
    }

    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          password: trimmed,
          data: const {'clover_password_set': true},
        ),
      );
      final user = response.user ?? _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthFailure(AuthErrorCode.supabaseUserMissing);
      }
      await _persistSession(user);
      await _cacheHasPassword(user.id);
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw AuthFailure(
        AuthErrorMapper.resolve(error) == AuthErrorCode.supabaseSignInFailed
            ? AuthErrorCode.passwordUpdateFailed
            : AuthErrorMapper.resolve(error),
      );
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw const AuthFailure(AuthErrorCode.passwordUpdateFailed);
    }
  }

  Future<void> signOut() async {
    await _pushMessaging.detachForSignOut();
    await _sessionCleanup.clear();
    await _supabase.auth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistSession(User user) async {
    await _storage.write<String>(key: AccountStorageKeys.authUserId, value: user.id);
  }

  /// Legacy password accounts: stamp metadata so register OTP stays blocked.
  Future<void> _ensurePasswordSetMetadata(User user) async {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    if (meta['clover_password_set'] == true) return;
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'clover_password_set': true}),
      );
    } catch (_) {
      // ignore — login already succeeded
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  void _assertEmail(String email) {
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthFailure(AuthErrorCode.emailInvalid);
    }
  }
}
