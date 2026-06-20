import 'package:clover/feature/message_page/data/models/message_chat_preview.dart';

abstract final class MessageChatPreviewMock {
  static List<MessageChatPreview> chats() {
    final now = DateTime.now();

    return [
      MessageChatPreview(
        id: '1',
        username: 'alina_design',
        lastMessage: 'Отправлю макет сегодня вечером',
        lastMessageAt: now.subtract(const Duration(minutes: 12)),
        isLastMessageMine: false,
        isRead: false,
        unreadCount: 2,
      ),
      MessageChatPreview(
        id: '2',
        username: 'marat_dev',
        lastMessage: 'Ок, созвонимся завтра в 11',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        isLastMessageMine: true,
        isRead: true,
      ),
      MessageChatPreview(
        id: '3',
        username: 'clover_studio',
        lastMessage: 'Фото для поста уже в облаке',
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        isLastMessageMine: true,
        isRead: false,
      ),
      MessageChatPreview(
        id: '4',
        username: 'nurlan_photo',
        lastMessage: 'Спасибо, посмотрю!',
        lastMessageAt: now.subtract(const Duration(days: 1, hours: 3)),
        isLastMessageMine: false,
        isRead: true,
      ),
      MessageChatPreview(
        id: '5',
        username: 'diana_events',
        lastMessage: 'Можем перенести встречу на пятницу?',
        lastMessageAt: now.subtract(const Duration(days: 2)),
        isLastMessageMine: false,
        isRead: false,
        unreadCount: 1,
      ),
      MessageChatPreview(
        id: '6',
        username: 'bekzat_work',
        lastMessage: 'Договор подписан ✓',
        lastMessageAt: now.subtract(const Duration(days: 4)),
        isLastMessageMine: true,
        isRead: true,
      ),
    ];
  }
}
