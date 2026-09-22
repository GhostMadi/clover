/// Локальные моки UI отзывов по точкам записи.
///
/// Включи [enabled], чтобы пощупать на профиле без бэка.
/// Перед прод-проходом / пока фича на паузе: `enabled = false`.
/// План: [docs/business/point-reviews-plan.md].
abstract final class PointReviewsMock {
  static const bool enabled = false;

  static const average = 4.8;
  static const totalCount = 128;

  static const pointAll = 'all';
  static const pointAbay = 'abay';
  static const pointDostyk = 'dostyk';

  static const points = <({String id, String label})>[
    (id: pointAll, label: 'Все точки'),
    (id: pointAbay, label: 'Салон на Абая'),
    (id: pointDostyk, label: 'Филиал Достык'),
  ];

  /// Ответы хозяина в сессии (mock, не сохраняются).
  static final Map<String, String> hostReplies = {
    'r1': 'Спасибо! Рады, что всё понравилось.',
  };

  static List<PointReviewMockItem> reviews({String pointId = pointAll}) {
    final all = <PointReviewMockItem>[
      PointReviewMockItem(
        id: 'r1',
        authorName: 'Айгерим К.',
        pointId: pointAbay,
        pointLabel: 'Салон на Абая',
        stars: 5,
        dateLabel: '12 мар',
        text: 'Отличная стрижка, мастер попал в образ. Запись без очереди.',
        hostReply: hostReplies['r1'],
      ),
      PointReviewMockItem(
        id: 'r2',
        authorName: 'Данияр М.',
        pointId: pointDostyk,
        pointLabel: 'Филиал Достык',
        stars: 4,
        dateLabel: '3 мар',
        text: 'Хорошо, но ждали чуть дольше. Салон чистый.',
        hostReply: hostReplies['r2'],
      ),
      PointReviewMockItem(
        id: 'r3',
        authorName: 'Сабина Т.',
        pointId: pointAbay,
        pointLabel: 'Салон на Абая',
        stars: 5,
        dateLabel: '20 фев',
        text: 'Уже третий раз здесь. Рекомендую.',
        hostReply: hostReplies['r3'],
      ),
      PointReviewMockItem(
        id: 'r4',
        authorName: 'Ерлан Б.',
        pointId: pointDostyk,
        pointLabel: 'Филиал Достык',
        stars: 5,
        dateLabel: '8 фев',
        text: 'Удобная запись, всё вовремя.',
        hostReply: hostReplies['r4'],
      ),
    ];
    if (pointId == pointAll) return all;
    return all.where((r) => r.pointId == pointId).toList(growable: false);
  }

  static void setHostReply(String reviewId, String text) {
    final t = text.trim();
    if (t.isEmpty) {
      hostReplies.remove(reviewId);
    } else {
      hostReplies[reviewId] = t;
    }
  }
}

final class PointReviewMockItem {
  const PointReviewMockItem({
    required this.id,
    required this.authorName,
    required this.pointId,
    required this.pointLabel,
    required this.stars,
    required this.dateLabel,
    required this.text,
    this.hostReply,
  });

  final String id;
  final String authorName;
  final String pointId;
  final String pointLabel;
  final int stars;
  final String dateLabel;
  final String text;
  final String? hostReply;
}
