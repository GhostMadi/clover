import 'package:clover/core/auth/errors/auth_error_code.dart';

/// Domain-level auth failure. Carries only [code], never raw provider text.
final class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.retryAfterSeconds});

  final AuthErrorCode code;
  final int? retryAfterSeconds;

  @override
  String toString() => 'AuthFailure(${code.value})';
}
