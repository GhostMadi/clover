import 'package:clover/feature/chat_page/data/models/chat_message.dart';

abstract final class ChatMessageMock {
  static List<ChatMessage> messagesForChat(String chatId) {
    final now = DateTime.now();

    return switch (chatId) {
      '1' => [
          ChatMessage(
            id: '1-1',
            text: 'Привет! Как продвигается проект?',
            sentAt: now.subtract(const Duration(hours: 3, minutes: 20)),
            isMine: false,
          ),
          ChatMessage(
            id: '1-2',
            text: 'Привет! Почти закончил первый блок',
            sentAt: now.subtract(const Duration(hours: 3, minutes: 5)),
            isMine: true,
            isRead: true,
          ),
          ChatMessage(
            id: '1-3',
            text: 'Супер, жду превью',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 40)),
            isMine: false,
          ),
          ChatMessage(
            id: '1-4',
            text: 'Отправлю макет сегодня вечером',
            sentAt: now.subtract(const Duration(minutes: 12)),
            isMine: false,
          ),
        ],
      '2' => [
          ChatMessage(
            id: '2-1',
            text: 'Можем созвониться завтра?',
            sentAt: now.subtract(const Duration(hours: 5)),
            isMine: false,
          ),
          ChatMessage(
            id: '2-2',
            text: 'Да, после 11 удобно',
            sentAt: now.subtract(const Duration(hours: 4, minutes: 30)),
            isMine: true,
            isRead: true,
          ),
          ChatMessage(
            id: '2-3',
            text: 'Ок, созвонимся завтра в 11',
            sentAt: now.subtract(const Duration(hours: 2)),
            isMine: true,
            isRead: true,
          ),
        ],
      _ => [
          ChatMessage(
            id: '$chatId-1',
            text: 'Привет!',
            sentAt: now.subtract(const Duration(hours: 1)),
            isMine: false,
          ),
          ChatMessage(
            id: '$chatId-2',
            text: 'Привет, напиши когда будешь на связи',
            sentAt: now.subtract(const Duration(minutes: 20)),
            isMine: true,
            isRead: false,
          ),
        ],
    };
  }
}
