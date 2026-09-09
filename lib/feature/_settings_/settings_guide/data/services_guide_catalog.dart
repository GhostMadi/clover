import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/widgets.dart';

/// Ключи гайда всех сервисов — [docs/business/services-guide.md].
enum ServicesGuideTopic {
  booking('booking'),
  attendance('attendance'),
  resources('resources');

  const ServicesGuideTopic(this.key);

  final String key;

  static ServicesGuideTopic? tryParse(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    for (final topic in ServicesGuideTopic.values) {
      if (topic.key == value) return topic;
    }
    return null;
  }

  AppServiceKind? get serviceKind => switch (this) {
        ServicesGuideTopic.booking => AppServiceKind.booking,
        ServicesGuideTopic.attendance => AppServiceKind.attendance,
        ServicesGuideTopic.resources => kResourcesService,
      };
}

class ServicesGuideStep {
  const ServicesGuideStep({required this.title, required this.body});

  final String title;
  final String body;
}

class ServicesGuideContent {
  const ServicesGuideContent({
    required this.topic,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.pageTitle,
    required this.lead,
    required this.steps,
  });

  final ServicesGuideTopic topic;
  final String cardTitle;
  final String cardSubtitle;
  final String pageTitle;
  final String lead;
  final List<ServicesGuideStep> steps;

  IconData get cardIcon => switch (topic) {
        ServicesGuideTopic.booking => AppIcons.calendarMonth.icon,
        ServicesGuideTopic.attendance => AppIcons.schedule.icon,
        ServicesGuideTopic.resources => AppIcons.inventory.icon,
      };
}

/// Каталог общего гайда сервисов (тексты на клиенте).
abstract final class ServicesGuideCatalog {
  static const List<ServicesGuideContent> all = [
    ServicesGuideContent(
      topic: ServicesGuideTopic.booking,
      cardTitle: 'Запись',
      cardSubtitle: 'Услуги, inbox и расписание',
      pageTitle: 'Запись',
      lead:
          'Сервис для хозяина витрины: услуги, заявки клиентов и расписание. '
          'Клиент бронирует без вашего тега хозяина.',
      steps: [
        ServicesGuideStep(
          title: 'Тег',
          body: 'Включите тег booking на профиле — появится хаб «Запись» в настройках и ярлык на профиле.',
        ),
        ServicesGuideStep(
          title: 'Услуги и inbox',
          body: 'Создайте услуги, принимайте и ведите заявки в inbox хозяина.',
        ),
        ServicesGuideStep(
          title: 'Клиент',
          body: '«Мои бронирования» — где вы клиент. Тег хозяина для этого не нужен.',
        ),
        ServicesGuideStep(
          title: 'Исполнители',
          body: 'Можно пригласить исполнителя карточкой в чат — он примет или отклонит приглашение.',
        ),
      ],
    ),
    ServicesGuideContent(
      topic: ServicesGuideTopic.attendance,
      cardTitle: 'Посещаемость',
      cardSubtitle: 'Компании, геозона и punch',
      pageTitle: 'Посещаемость',
      lead:
          'Учёт смен и присутствия: компании, геозона, работники и punch с телефона.',
      steps: [
        ServicesGuideStep(
          title: 'Теги',
          body: 'attendance — admin компании; attendanceWork — работник (punch).',
        ),
        ServicesGuideStep(
          title: 'Компания',
          body: 'Создайте компанию, настройте геозону и пригласите людей в команду.',
        ),
        ServicesGuideStep(
          title: 'Punch',
          body: 'Работник отмечает приход/уход с телефона в зоне компании.',
        ),
        ServicesGuideStep(
          title: 'Отчёты',
          body: 'Admin видит табель, аналитику и настройки оплаты смен.',
        ),
      ],
    ),
    ServicesGuideContent(
      topic: ServicesGuideTopic.resources,
      cardTitle: 'Ресурсы',
      cardSubtitle: 'Места и фильтры витрины',
      pageTitle: 'Ресурсы',
      lead:
          'Личный набор автора: местоположения для постов и свои фильтры сетки профиля.',
      steps: [
        ServicesGuideStep(
          title: 'Тег',
          body: 'Тег resources открывает хаб «Ресурсы» в настройках.',
        ),
        ServicesGuideStep(
          title: 'Местоположения',
          body: 'Сохраните адреса один раз и выбирайте их в композере поста.',
        ),
        ServicesGuideStep(
          title: 'Фильтры витрины',
          body: 'Свои категории и значения — чипы на профиле и метки у постов. Не путать с фильтром ленты Home.',
        ),
      ],
    ),
  ];

  static ServicesGuideContent byTopic(ServicesGuideTopic topic) {
    return all.firstWhere((item) => item.topic == topic);
  }

  static ServicesGuideContent? tryByKey(String key) {
    final topic = ServicesGuideTopic.tryParse(key);
    if (topic == null) return null;
    return byTopic(topic);
  }
}
