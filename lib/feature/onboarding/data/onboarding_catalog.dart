import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:clover/l10n/app_localizations.dart';
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

  static List<OnboardingSlideData> slidesFor(OnboardingPath path, AppLocalizations l10n) {
    return switch (path) {
      OnboardingPath.feed => feedSlides(l10n),
      OnboardingPath.business => businessSlides(l10n),
      OnboardingPath.both => bothSlides(l10n),
    };
  }

  static List<OnboardingSlideData> feedSlides(AppLocalizations l10n) => [
        OnboardingSlideData(
          emoji: '✨',
          title: l10n.onboarding_slide_feed_1_title,
          body: l10n.onboarding_slide_feed_1_body,
          tip: l10n.onboarding_slide_feed_1_tip,
          illustration: OnboardingIllustrationKind.feedMap,
        ),
        OnboardingSlideData(
          emoji: '🏪',
          title: l10n.onboarding_slide_feed_2_title,
          body: l10n.onboarding_slide_feed_2_body,
          tip: l10n.onboarding_slide_feed_2_tip,
          illustration: OnboardingIllustrationKind.profile,
        ),
        OnboardingSlideData(
          emoji: '📅',
          title: l10n.onboarding_slide_feed_3_title,
          body: l10n.onboarding_slide_feed_3_body,
          tip: l10n.onboarding_slide_feed_3_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
        OnboardingSlideData(
          emoji: '💬',
          title: l10n.onboarding_slide_feed_4_title,
          body: l10n.onboarding_slide_feed_4_body,
          tip: l10n.onboarding_slide_feed_4_tip,
          illustration: OnboardingIllustrationKind.chat,
        ),
        OnboardingSlideData(
          emoji: '🔎',
          title: l10n.onboarding_slide_feed_5_title,
          body: l10n.onboarding_slide_feed_5_body,
          tip: l10n.onboarding_slide_feed_5_tip,
          illustration: OnboardingIllustrationKind.feedMap,
        ),
        OnboardingSlideData(
          emoji: '🍀',
          title: l10n.onboarding_slide_feed_6_title,
          body: l10n.onboarding_slide_feed_6_body,
          tip: l10n.onboarding_slide_feed_6_tip,
          illustration: OnboardingIllustrationKind.welcome,
        ),
      ];

  static List<OnboardingSlideData> businessSlides(AppLocalizations l10n) => [
        OnboardingSlideData(
          emoji: '🏢',
          title: l10n.onboarding_slide_biz_1_title,
          body: l10n.onboarding_slide_biz_1_body,
          tip: l10n.onboarding_slide_biz_1_tip,
          illustration: OnboardingIllustrationKind.welcome,
        ),
        OnboardingSlideData(
          emoji: '⚡',
          title: l10n.onboarding_slide_biz_2_title,
          body: l10n.onboarding_slide_biz_2_body,
          tip: l10n.onboarding_slide_biz_2_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
        OnboardingSlideData(
          emoji: '🌟',
          title: l10n.onboarding_slide_biz_3_title,
          body: l10n.onboarding_slide_biz_3_body,
          tip: l10n.onboarding_slide_biz_3_tip,
          illustration: OnboardingIllustrationKind.profile,
        ),
        OnboardingSlideData(
          emoji: '📅',
          title: l10n.onboarding_slide_biz_4_title,
          body: l10n.onboarding_slide_biz_4_body,
          tip: l10n.onboarding_slide_biz_4_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
        OnboardingSlideData(
          emoji: '🤝',
          title: l10n.onboarding_slide_biz_5_title,
          body: l10n.onboarding_slide_biz_5_body,
          tip: l10n.onboarding_slide_biz_5_tip,
          illustration: OnboardingIllustrationKind.feedMap,
        ),
      ];

  static List<OnboardingSlideData> bothSlides(AppLocalizations l10n) => [
        OnboardingSlideData(
          emoji: '🍀',
          title: l10n.onboarding_slide_both_1_title,
          body: l10n.onboarding_slide_both_1_body,
          tip: l10n.onboarding_slide_both_1_tip,
          illustration: OnboardingIllustrationKind.welcome,
        ),
        OnboardingSlideData(
          emoji: '✨',
          title: l10n.onboarding_slide_both_2_title,
          body: l10n.onboarding_slide_both_2_body,
          tip: l10n.onboarding_slide_both_2_tip,
          illustration: OnboardingIllustrationKind.feedMap,
        ),
        OnboardingSlideData(
          emoji: '⚡',
          title: l10n.onboarding_slide_both_3_title,
          body: l10n.onboarding_slide_both_3_body,
          tip: l10n.onboarding_slide_both_3_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
        OnboardingSlideData(
          emoji: '🌟',
          title: l10n.onboarding_slide_both_4_title,
          body: l10n.onboarding_slide_both_4_body,
          tip: l10n.onboarding_slide_both_4_tip,
          illustration: OnboardingIllustrationKind.profile,
        ),
        OnboardingSlideData(
          emoji: '✨',
          title: l10n.onboarding_slide_both_5_title,
          body: l10n.onboarding_slide_both_5_body,
          tip: l10n.onboarding_slide_both_5_tip,
          illustration: OnboardingIllustrationKind.welcome,
        ),
      ];
}
