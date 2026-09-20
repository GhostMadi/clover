import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:flutter/material.dart';

/// Сюжет стартового тура (v2).
enum OnboardingPath {
  /// Обычный пользователь: лента, ивенты, запись, бонусы, места.
  feed,
  /// Бизнес / предприятие: витрина, супер-теги, сервисы.
  business,
  /// И лента, и дело.
  both,
}

/// Контент одного слайда стартового онбординга.
@immutable
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.illustration,
    this.tip,
  });

  final String emoji;
  final String title;
  final String body;
  final String? tip;
  final OnboardingIllustrationKind illustration;
}

enum OnboardingIllustrationKind {
  welcome,
  feedMap,
  create,
  chat,
  profile,
  services,
}

/// Каталог онбордингов: app v2 с ветками; service tips — на будущее.
abstract final class OnboardingCatalog {
  static const appFlowId = OnboardingTipId.appV2;

  /// @Deprecated — v1 mono-flow; оставлен для истории, UI больше не использует.
  static const appV1Id = OnboardingTipId.appV1;

  static List<OnboardingSlideData> slidesFor(OnboardingPath path) {
    return switch (path) {
      OnboardingPath.feed => feedSlides,
      OnboardingPath.business => businessSlides,
      OnboardingPath.both => bothSlides,
    };
  }

  static const feedSlides = <OnboardingSlideData>[
    OnboardingSlideData(
      emoji: '✨',
      title: 'Что происходит',
      body: 'Ивенты, новости, живой ритм города — мягко и рядом.',
      tip: 'Лента и карта в одном Clover.',
      illustration: OnboardingIllustrationKind.feedMap,
    ),
    OnboardingSlideData(
      emoji: '🏪',
      title: 'Места рядом',
      body: 'Загляни к салону, кафе или магазину — мягко узнай их мир.',
      tip: 'Страница места в Clover.',
      illustration: OnboardingIllustrationKind.profile,
    ),
    OnboardingSlideData(
      emoji: '📅',
      title: 'Запись и бонусы',
      body: 'Записывайся на услуги. Копи и трать бонусы там, где это доступно.',
      tip: 'Всё для тебя — без лишних шагов.',
      illustration: OnboardingIllustrationKind.services,
    ),
    OnboardingSlideData(
      emoji: '💬',
      title: 'Поделись с близкими',
      body: 'Напиши другу. Позови на ивент. Тёплый чат — просто рядом.',
      tip: 'Общение без суеты.',
      illustration: OnboardingIllustrationKind.chat,
    ),
    OnboardingSlideData(
      emoji: '🔎',
      title: 'Найди своё',
      body: 'Фильтры помогут отсеять шум и оставить только то, что откликается.',
      tip: 'Тихо. Точно. По-твоему.',
      illustration: OnboardingIllustrationKind.feedMap,
    ),
    OnboardingSlideData(
      emoji: '🍀',
      title: 'Clover с тобой',
      body: 'Смотри · записывайся · пиши своим · копи бонусы. Легко и тепло.',
      tip: 'Повторить тур: Настройки → О приложении.',
      illustration: OnboardingIllustrationKind.welcome,
    ),
  ];

  static const businessSlides = <OnboardingSlideData>[
    OnboardingSlideData(
      emoji: '🏢',
      title: 'Для бизнеса',
      body: 'Один аккаунт — витрина и сервисы. Спокойно и по делу.',
      tip: 'Сначала лицо, потом инструменты.',
      illustration: OnboardingIllustrationKind.welcome,
    ),
    OnboardingSlideData(
      emoji: '⚡',
      title: 'Супер-теги',
      body: 'Включаешь тег — открывается сила. Запись, команда, точки.',
      tip: 'Мало тегов — ясный фокус.',
      illustration: OnboardingIllustrationKind.services,
    ),
    OnboardingSlideData(
      emoji: '🌟',
      title: 'Живая витрина',
      body: 'Профиль, к которому хочется вернуться. Доверие без крика.',
      tip: 'Красота и ясность.',
      illustration: OnboardingIllustrationKind.profile,
    ),
    OnboardingSlideData(
      emoji: '📅',
      title: 'Сервисы рядом',
      body: 'Запись, бонусы на услугах, всё под рукой.',
      tip: 'Гайды — в Настройки → Сервисы.',
      illustration: OnboardingIllustrationKind.services,
    ),
    OnboardingSlideData(
      emoji: '🤝',
      title: 'Клиент находит тебя',
      body: 'В ленте, на карте, через запись. Вы уже в Clover.',
      tip: 'Мягкий путь к людям.',
      illustration: OnboardingIllustrationKind.feedMap,
    ),
  ];

  static const bothSlides = <OnboardingSlideData>[
    OnboardingSlideData(
      emoji: '🍀',
      title: 'И лента, и дело',
      body: 'Для себя — город и запись. Для дела — витрина и сервисы.',
      tip: 'Один Clover. Два ритма.',
      illustration: OnboardingIllustrationKind.welcome,
    ),
    OnboardingSlideData(
      emoji: '✨',
      title: 'Как для себя',
      body: 'Ивенты, места, запись, бонусы, фильтры — всё открыто.',
      tip: 'Живи в городе спокойно.',
      illustration: OnboardingIllustrationKind.feedMap,
    ),
    OnboardingSlideData(
      emoji: '⚡',
      title: 'Когда ведёшь дело',
      body: 'Супер-теги включают запись и другие сервисы.',
      tip: 'Включай по мере надобности.',
      illustration: OnboardingIllustrationKind.services,
    ),
    OnboardingSlideData(
      emoji: '🌟',
      title: 'Одна витрина',
      body: 'Профиль — и лицо, и точка входа для клиентов.',
      tip: 'Мягко и понятно.',
      illustration: OnboardingIllustrationKind.profile,
    ),
    OnboardingSlideData(
      emoji: '✨',
      title: 'Маленький старт',
      body: 'Оформи себя. Посмотри ленту. Включи сервис, когда будешь готов.',
      tip: 'Повторить тур: Настройки → О приложении.',
      illustration: OnboardingIllustrationKind.welcome,
    ),
  ];
}
