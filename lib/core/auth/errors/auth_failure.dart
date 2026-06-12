import 'package:clover/core/auth/errors/auth_error_code.dart';

/// Domain-level auth failure. Carries only [code], never raw provider text.
final class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthFailure(${code.value})';
}
