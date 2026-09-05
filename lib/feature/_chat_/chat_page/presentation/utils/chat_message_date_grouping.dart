import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';

/// Groups chat messages by calendar day (chronological order).
abstract final class ChatMessageDateGrouping {
  ChatMessageDateGrouping._();

  static const _monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String dayLabel(DateTime sentAt) {
    final local = sentAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;

    if (diffDays == 0) return 'Сегодня';
    if (diffDays == 1) return 'Вчера';

    final month = _monthsGenitive[local.month - 1];
    if (local.year == now.year) {
      return '${local.day} $month';
    }
    return '${local.day} $month ${local.year}';
  }

  static List<(String dayLabel, List<ChatMessage> messages)> group(List<ChatMessage> messages) {
    if (messages.isEmpty) return const [];

    final sections = <(String, List<ChatMessage>)>[];
    String? currentLabel;
    List<ChatMessage>? bucket;

    for (final message in messages) {
      final label = dayLabel(message.sentAt);
      if (label != currentLabel) {
        if (bucket != null && currentLabel != null) {
          sections.add((currentLabel, bucket));
        }
        currentLabel = label;
        bucket = [message];
      } else {
        bucket!.add(message);
      }
    }

    if (bucket != null && currentLabel != null) {
      sections.add((currentLabel, bucket));
    }

    return sections;
  }

  static int listItemCount(List<(String, List<ChatMessage>)> sections) {
    var count = 0;
    for (final (_, sectionMessages) in sections) {
      count += 1 + sectionMessages.length;
    }
    return count;
  }

  static ChatMessage? messageAt(List<(String, List<ChatMessage>)> sections, int index) {
    var cursor = 0;
    for (final (_, sectionMessages) in sections) {
      cursor++; // header
      for (final message in sectionMessages) {
        if (index == cursor) return message;
        cursor++;
      }
    }
    return null;
  }

  static bool isHeaderIndex(List<(String, List<ChatMessage>)> sections, int index) {
    var cursor = 0;
    for (final section in sections) {
      if (index == cursor) return true;
      cursor += 1 + section.$2.length;
    }
    return false;
  }

  static String? headerTitleAt(List<(String, List<ChatMessage>)> sections, int index) {
    var cursor = 0;
    for (final (label, sectionMessages) in sections) {
      if (index == cursor) return label;
      cursor += 1 + sectionMessages.length;
    }
    return null;
  }
}
