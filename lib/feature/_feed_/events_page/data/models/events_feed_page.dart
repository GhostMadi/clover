import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';

class EventsFeedPage {
  const EventsFeedPage({
    required this.items,
    required this.hasMore,
  });

  final List<PostFeedItem> items;
  final bool hasMore;
}
