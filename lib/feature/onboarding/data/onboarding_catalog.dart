import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:flutter/material.dart';

/// Контент одного слайда стартового онбординга.
@immutable
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String emoji;
  final String title;
  final String body;
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

/// Каталог онбордингов: app-flow сейчас, service tips — на будущее.
abstract final class OnboardingCatalog {
  static const appV1Id = OnboardingTipId.appV1;

  static const appV1Slides = <OnboardingSlideData>[
    OnboardingSlideData(
      emoji: '🍀',
      title: 'Clover — жизнь ярче, бизнес умнее',
      body:
          'Классный инструмент для бизнеса и для тех, кто устал от серых будней. '
          'События, люди и сервисы — в одном месте ✨',
      illustration: OnboardingIllustrationKind.welcome,
    ),
    OnboardingSlideData(
      emoji: '🗺️',
      title: 'Лента и карта города',
      body:
          'Ищи, что происходит рядом: концерты, встречи, места. '
          'Двойной тап по Home — и ты уже на карте 📍',
      illustration: OnboardingIllustrationKind.feedMap,
    ),
    OnboardingSlideData(
      emoji: '📌',
      title: 'Создавай своё',
      body:
          'Ставь маркер, публикуй пост с фото, собирай реакции. '
          'Город узнаёт о тебе — ты перестаёшь скучать 🚀',
      illustration: OnboardingIllustrationKind.create,
    ),
    OnboardingSlideData(
      emoji: '💬',
      title: 'Чат всегда под рукой',
      body:
          'Пиши организаторам, друзьям и клиентам прямо в Clover. '
          'Быстрые ответы без лишних приложений ⚡',
      illustration: OnboardingIllustrationKind.chat,
    ),
    OnboardingSlideData(
      emoji: '👤',
      title: 'Твой профиль — твоя витрина',
      body:
          'Оформи себя или бренд: фото, описание, подборки. '
          'Для гостя — лицо в городе, для бизнеса — живая витрина 🌟',
      illustration: OnboardingIllustrationKind.profile,
    ),
    OnboardingSlideData(
      emoji: '💼',
      title: 'Сервисы, которые работают на тебя',
      body:
          'Онлайн-запись 📅 — услуги, слоты и клиенты в одном месте. '
          'Бонусы ⭐ настраиваешь на услуге: начисление и оплату лояльностью. '
          'Гостю — записаться и копить баллы. Погнали 🍀',
      illustration: OnboardingIllustrationKind.services,
    ),
  ];
}
