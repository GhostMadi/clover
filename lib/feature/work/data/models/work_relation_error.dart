import 'package:supabase_flutter/supabase_flutter.dart';

/// Человекочитаемая ошибка RPC relations / work-флагов.
class WorkRelationError implements Exception {
  WorkRelationError(this.message);

  final String message;

  @override
  String toString() => message;

  static WorkRelationError from(Object error) {
    if (error is WorkRelationError) return error;
    if (error is PostgrestException) {
      return WorkRelationError(_mapMessage(error.message));
    }
    return WorkRelationError('$error');
  }

  static String _mapMessage(String raw) {
    final code = raw.trim().toLowerCase();
    if (code.contains('relation_already_active_or_pending')) {
      return 'Заявка уже отправлена или связь уже активна';
    }
    if (code.contains('only_initiator_can_withdraw')) {
      return 'Отменить заявку может только её автор';
    }
    if (code.contains('can_only_withdraw_pending')) {
      return 'Можно отменить только заявку в ожидании';
    }
    if (code.contains('not_authenticated')) {
      return 'Войдите в аккаунт';
    }
    if (code.contains('cannot_self_request')) {
      return 'Нельзя отправить заявку самому себе';
    }
    if (code.contains('user_not_found')) {
      return 'Пользователь не найден';
    }
    if (code.contains('invalid_action')) {
      return 'Недопустимый тип заявки';
    }
    return raw;
  }
}
