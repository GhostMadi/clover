import 'package:clover/feature/notification_page/data/models/notification_item.dart';

enum NotificationDateSection {
  today,
  yesterday,
  last7Days,
  last30Days,
  earlier,
}

abstract final class NotificationDateGrouping {
  NotificationDateGrouping._();

  static String title(NotificationDateSection section) => switch (section) {
    NotificationDateSection.today => 'Сегодня',
    NotificationDateSection.yesterday => 'Вчера',
    NotificationDateSection.last7Days => 'Последние 7 дней',
    NotificationDateSection.last30Days => 'Последние 30 дней',
    NotificationDateSection.earlier => 'Раньше',
  };

  static NotificationDateSection sectionFor(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(day).inDays;

    if (diffDays == 0) return NotificationDateSection.today;
    if (diffDays == 1) return NotificationDateSection.yesterday;
    if (diffDays < 7) return NotificationDateSection.last7Days;
    if (diffDays < 30) return NotificationDateSection.last30Days;
    return NotificationDateSection.earlier;
  }

  static List<(NotificationDateSection section, List<NotificationItem> items)> group(
    List<NotificationItem> items,
  ) {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final buckets = <NotificationDateSection, List<NotificationItem>>{};
    for (final item in sorted) {
      final section = sectionFor(item.createdAt);
      buckets.putIfAbsent(section, () => []).add(item);
    }

    const order = NotificationDateSection.values;
    final grouped = <(NotificationDateSection, List<NotificationItem>)>[];
    for (final section in order) {
      final bucket = buckets[section];
      if (bucket != null && bucket.isNotEmpty) {
        grouped.add((section, bucket));
      }
    }
    return grouped;
  }
}
