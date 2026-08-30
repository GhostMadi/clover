import 'package:clover/feature/_post_/post_create/model/post_create_compose_result.dart';

extension PostCreateComposeResultValidation on PostCreateComposeResult {
  /// Период выбран — публикация + ивент на карте.
  bool get isEvent => eventPeriod != null;

  /// Кнопка «Опубликовать» активна, пока есть медиа из редактора.
  bool get canPublish => media.isNotEmpty;

  /// Проверка перед отправкой; `null` — можно публиковать.
  String? get publishBlockReason {
    if (media.isEmpty) return 'Добавьте хотя бы одно фото';
    if (!isEvent) return null;

    if (textEmoji.trim().isEmpty) return 'Выберите эмодзи';
    if (location == null) return 'Выберите местоположение';
    if (!_hasCoordinates) return 'У местоположения нет координат';

    final period = eventPeriod!;
    if (period.duration.inMinutes <= 0) return 'Укажите длительность события';
    if (period.duration > const Duration(hours: 24)) {
      return 'Длительность события не более 24 ч';
    }

    return null;
  }

  bool get _hasCoordinates {
    final loc = location;
    if (loc == null) return false;
    return loc.latitude != null && loc.longitude != null;
  }
}
