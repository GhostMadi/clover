import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/l10n/app_localizations.dart';

enum NotificationDateSection {
  today,
  yesterday,
  last7Days,
  last30Days,
}

abstract final class NotificationDateGrouping {
  NotificationDateGrouping._();

  static const retentionDays = 30;

  static DateTime get retentionCutoff {
    final now = DateTime.now();
    return now.subtract(const Duration(days: retentionDays));
  }

  static bool isWithinRetention(DateTime createdAt) =>
      !createdAt.toLocal().isBefore(retentionCutoff);

  static String title(NotificationDateSection section, AppLocalizations l10n) => switch (section) {
        NotificationDateSection.today => l10n.common_today,
        NotificationDateSection.yesterday => l10n.common_yesterday,
        NotificationDateSection.last7Days => l10n.feed_notif_section_last7,
        NotificationDateSection.last30Days => l10n.feed_notif_section_last30,
      };

  static NotificationDateSection? sectionFor(DateTime createdAt) {
    if (!isWithinRetention(createdAt)) return null;

    final local = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(day).inDays;

    if (diffDays == 0) return NotificationDateSection.today;
    if (diffDays == 1) return NotificationDateSection.yesterday;
    if (diffDays < 7) return NotificationDateSection.last7Days;
    return NotificationDateSection.last30Days;
  }

  static List<(NotificationDateSection section, List<NotificationItem> items)> group(
    List<NotificationItem> items,
  ) {
    final sorted = [
      for (final item in items)
        if (isWithinRetention(item.createdAt)) item,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final buckets = <NotificationDateSection, List<NotificationItem>>{};
    for (final item in sorted) {
      final section = sectionFor(item.createdAt);
      if (section == null) continue;
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
