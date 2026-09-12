import 'package:clover/core/resources/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Ключи карточек гайда «Ресурсы» — см. [docs/business/resources-guide.md].
enum ResourcesGuideTopic {
  overview('overview'),
  locations('locations'),
  filters('filters');

  const ResourcesGuideTopic(this.key);

  final String key;

  static ResourcesGuideTopic? tryParse(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    for (final topic in ResourcesGuideTopic.values) {
      if (topic.key == value) return topic;
    }
    return null;
  }
}

class ResourcesGuideStep {
  const ResourcesGuideStep({required this.title, required this.body});

  final String title;
  final String body;
}

class ResourcesGuideContent {
  const ResourcesGuideContent({
    required this.topic,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.pageTitle,
    required this.lead,
    required this.steps,
    this.ctaLabel,
  });

  final ResourcesGuideTopic topic;
  final String cardTitle;
  final String cardSubtitle;
  final String pageTitle;
  final String lead;
  final List<ResourcesGuideStep> steps;

  /// Кнопка внизу гайда → справочник (null = только закрыть/назад).
  final String? ctaLabel;

  IconData get cardIcon => switch (topic) {
    ResourcesGuideTopic.overview => AppIcons.inventory.icon,
    ResourcesGuideTopic.locations => AppIcons.locationOn.icon,
    ResourcesGuideTopic.filters => AppIcons.tune.icon,
  };
}

/// Каталог гайда ресурсов (тексты на клиенте).
abstract final class ResourcesGuideCatalog {
  static const List<ResourcesGuideContent> all = [
    ResourcesGuideContent(
      topic: ResourcesGuideTopic.overview,
      cardTitle: 'Что такое ресурсы',
      cardSubtitle: 'Идея сервиса',
      pageTitle: 'Что такое ресурсы',
      lead:
          'Ресурсы — ваш личный справочник для витрины профиля: не лента города и не '
          '«настройки аккаунта», а то, чем вы наполняете публикации и как гости читают '
          'ваш профиль.',
      steps: [
        ResourcesGuideStep(
          title: 'Зачем',
          body:
              'Чтобы одни и те же места и метки не набирать каждый раз заново — и чтобы '
              'профиль собирался в понятную витрину, а не в свалку постов.',
        ),
        ResourcesGuideStep(
          title: 'Из чего состоит',
          body:
              'Два слоя: места (где происходило) и фильтры (как это классифицировать). '
              'Вместе они дают контекст посту и навигацию гостю по вашему профилю.',
        ),
        ResourcesGuideStep(
          title: 'Чего это не делает',
          body:
              'Не выбирает город ленты и карты, не заменяет запись или посещаемость. '
              'Только справочник автора витрины.',
        ),
      ],
      ctaLabel: null,
    ),
    ResourcesGuideContent(
      topic: ResourcesGuideTopic.locations,
      cardTitle: 'Местоположения',
      cardSubtitle: 'Точки на карте для постов',
      pageTitle: 'Местоположения',
      lead:
          'Личный справочник мест: адрес + координаты. Только ваши точки, не город ленты '
          'и не зоны доставки.',
      steps: [
        ResourcesGuideStep(
          title: 'Создать',
          body: 'Ресурсы → Местоположения → Добавить. Поставьте пин и укажите адрес.',
        ),
        ResourcesGuideStep(
          title: 'Использовать',
          body: 'В композере поста выберите активное место из списка.',
        ),
        ResourcesGuideStep(
          title: 'Активность',
          body: 'Неактивное место остаётся в списке, но его нельзя выбрать в новом посте.',
        ),
      ],
      ctaLabel: 'Открыть местоположения',
    ),
    ResourcesGuideContent(
      topic: ResourcesGuideTopic.filters,
      cardTitle: 'Фильтры витрины',
      cardSubtitle: 'Категории для сетки профиля',
      pageTitle: 'Фильтры витрины',
      lead:
          'Свои категории и значения, чтобы гости (и вы) фильтровали посты на профиле. '
          'Это не фильтр ленты Home.',
      steps: [
        ResourcesGuideStep(
          title: 'Создать категорию',
          body: 'Ресурсы → Фильтры → новая категория и значения внутри неё.',
        ),
        ResourcesGuideStep(
          title: 'На профиле',
          body: 'Чипы над сеткой сужают показ постов с выбранными метками.',
        ),
        ResourcesGuideStep(
          title: 'В посте',
          body: 'При публикации отметьте, к каким значениям относится пост.',
        ),
      ],
      ctaLabel: 'Открыть фильтры',
    ),
  ];

  static ResourcesGuideContent byTopic(ResourcesGuideTopic topic) {
    return all.firstWhere((item) => item.topic == topic);
  }

  static ResourcesGuideContent? tryByKey(String key) {
    final topic = ResourcesGuideTopic.tryParse(key);
    if (topic == null) return null;
    return byTopic(topic);
  }
}
