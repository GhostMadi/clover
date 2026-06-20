import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileError implements Exception {
  EditProfileError(this.message);

  final String message;

  @override
  String toString() => message;

  static EditProfileError from(Object error) {
    if (error is EditProfileError) return error;
    if (error is PostgrestException) {
      return EditProfileError(_mapMessage(error));
    }
    return EditProfileError('$error');
  }

  static String _mapMessage(PostgrestException error) {
    final raw = error.message.trim().toLowerCase();
    if (raw.contains('username_change_cooldown')) {
      final hint = error.hint?.trim();
      if (hint != null && hint.isNotEmpty) {
        return 'Смена никнейма будет доступна позже ($hint)';
      }
      return 'Смена никнейма временно недоступна';
    }
    if (raw.contains('username_change_limit_reached')) {
      return 'Лимит смен никнейма исчерпан';
    }
    if (raw.contains('duplicate') || raw.contains('unique') || raw.contains('username')) {
      return 'Этот никнейм уже занят';
    }
    if (raw.contains('not_authenticated')) {
      return 'Войдите в аккаунт';
    }
    return error.message;
  }
}
