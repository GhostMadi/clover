import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';

class NotificationsFeedPage {
  const NotificationsFeedPage({
    required this.items,
    required this.hasMore,
  });

  final List<NotificationItem> items;
  final bool hasMore;
}
