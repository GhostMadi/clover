import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_key.dart';
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

  /// Admin-тег, который «Активировать» вешает на профиль.
  MarkerTagKey get adminTag => switch (this) {
        ServicesGuideTopic.booking => MarkerTagKey.booking,
        ServicesGuideTopic.attendance => MarkerTagKey.attendance,
        ServicesGuideTopic.resources => MarkerTagKey.resources,
      };

  String get activateLabel => switch (this) {
        ServicesGuideTopic.booking => 'Активировать запись',
        ServicesGuideTopic.attendance => 'Активировать посещаемость',
        ServicesGuideTopic.resources => 'Активировать ресурсы',
      };

  String get openLabel => switch (this) {
        ServicesGuideTopic.booking => 'Открыть запись',
        ServicesGuideTopic.attendance => 'Открыть посещаемость',
        ServicesGuideTopic.resources => 'Открыть ресурсы',
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
      cardSubtitle: 'Услуги, заявки и расписание',
      pageTitle: 'Запись',
      lead:
          'Запись — когда вы принимаете клиентов: услуги, слоты и заявки в одном месте. '
          'Гость находит вас в городе и нажимает «Записаться».',
      steps: [
        ServicesGuideStep(
          title: 'Включите сервис',
          body:
              'Кнопка «Активировать» добавит тег записи на профиль. '
              'Появится хаб «Запись» в настройках и ярлык на вашей витрине.',
        ),
        ServicesGuideStep(
          title: 'Заведите услуги',
          body:
              'Назовите услугу, укажите длительность и доступность. '
              'Клиент видит понятный список и выбирает удобное время.',
        ),
        ServicesGuideStep(
          title: 'Принимайте заявки',
          body:
              'Новые брони приходят в inbox. Подтверждайте, переносите или отвечайте в чате — '
              'всё рядом, без лишней суеты.',
        ),
        ServicesGuideStep(
          title: 'Бонусы на услуге',
          body:
              'Лояльность настраивается у услуги: начисление и оплата баллами. '
              'Гость копит и тратит там, где вы это разрешили.',
        ),
        ServicesGuideStep(
          title: 'Команда',
          body:
              'Можно пригласить исполнителя из чата. Он получит свои заказы, '
              'а вы остаётесь хозяином витрины.',
        ),
      ],
    ),
    ServicesGuideContent(
      topic: ServicesGuideTopic.attendance,
      cardTitle: 'Посещаемость',
      cardSubtitle: 'Смены, геозона и команда',
      pageTitle: 'Посещаемость',
      lead:
          'Посещаемость — учёт прихода и ухода команды. '
          'Вы ведёте компанию и правила; сотрудники отмечаются с телефона.',
      steps: [
        ServicesGuideStep(
          title: 'Включите сервис',
          body:
              '«Активировать» повесит тег хозяина посещаемости. '
              'Откроется хаб в настройках и управление на профиле.',
        ),
        ServicesGuideStep(
          title: 'Создайте компанию',
          body:
              'Задайте точку, геозону и базовые правила смен. '
              'Так punch сработает только там, где нужно.',
        ),
        ServicesGuideStep(
          title: 'Пригласите людей',
          body:
              'Отправьте приглашение в команду. У сотрудника появится свой режим punch — '
              'отметить приход и уход.',
        ),
        ServicesGuideStep(
          title: 'Смотрите табель',
          body:
              'Смены, корректировки и аналитика собираются у вас. '
              'Меньше ручных таблиц — больше ясности.',
        ),
      ],
    ),
    ServicesGuideContent(
      topic: ServicesGuideTopic.resources,
      cardTitle: 'Ресурсы',
      cardSubtitle: 'Места и фильтры витрины',
      pageTitle: 'Ресурсы',
      lead:
          'Ресурсы — ваш личный справочник автора: сохранённые места для постов '
          'и фильтры, по которым гости читают витрину.',
      steps: [
        ServicesGuideStep(
          title: 'Включите сервис',
          body:
              '«Активировать» добавит тег ресурсов. '
              'Появится хаб «Ресурсы» — местоположения и фильтры.',
        ),
        ServicesGuideStep(
          title: 'Местоположения',
          body:
              'Сохраните адреса один раз. В композере поста выбираете точку из списка — '
              'без повторного поиска на карте.',
        ),
        ServicesGuideStep(
          title: 'Фильтры витрины',
          body:
              'Свои категории и значения на профиле. Гость быстрее понимает, кто вы '
              'и что у вас есть. Это не фильтр ленты Home.',
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
