import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Soft conversational accent from Clover [AppPalette] (не сырой hex).
///
/// Seed (chatId / peerId / username) → стабильный цвет, не «каждый раз новый».
///
/// «Жвачка / мультик»: пузыри всегда на light soft-пастелях (даже в dark theme),
/// чтобы не было тусклого «космоса». Текст на bubble — тёмный ink с light-палитры.
class ChatPeerAccent {
  const ChatPeerAccent({
    required this.fill,
    required this.ink,
    required this.onFill,
    required this.meta,
    this.border,
  });

  /// Soft bubble / avatar background (candy pastel).
  final Color fill;

  /// Same-hue accent (icons, initials, reply bar).
  final Color ink;

  /// Body text on [fill].
  final Color onFill;

  /// Time / meta on [fill].
  final Color meta;

  final Color? border;

  /// Всегда светлая soft-палитра — жвачка на любом фоне экрана.
  static const AppPalette _candy = AppPalette.light;

  /// Чуть сочнее пастель (мультик), без неонового glow.
  static Color _gum(Color fill, Color ink) {
    return Color.alphaBlend(ink.withValues(alpha: 0.16), fill);
  }

  /// Свои сообщения — soft mint gum + green ink.
  factory ChatPeerAccent.mine(AppPalette c) {
    final candy = _candy;
    final ink = candy.primary;
    return ChatPeerAccent(
      fill: _gum(candy.successSoft, ink),
      ink: ink,
      onFill: candy.textColor,
      meta: candy.subTextColor,
      border: candy.borderCardGreen,
    );
  }

  /// Чужие / аватар чата — candy soft + matching ink.
  factory ChatPeerAccent.forSeed(AppPalette c, String seed) {
    final candy = _candy;
    final slots = <ChatPeerAccent>[
      ChatPeerAccent(
        fill: _gum(candy.functionalSoftBlue, candy.functionalSoftBlueIcon),
        ink: candy.functionalSoftBlueIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardBlue,
      ),
      ChatPeerAccent(
        fill: _gum(candy.functionalSoftOrange, candy.functionalSoftOrangeIcon),
        ink: candy.functionalSoftOrangeIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
      ),
      ChatPeerAccent(
        fill: _gum(candy.functionalSoftLilac, candy.functionalSoftLilacIcon),
        ink: candy.functionalSoftLilacIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardLilac.withValues(alpha: 0.55),
      ),
      ChatPeerAccent(
        fill: _gum(candy.functionalSoftYellow, candy.functionalSoftYellowIcon),
        ink: candy.functionalSoftYellowIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardYellow,
      ),
      ChatPeerAccent(
        fill: _gum(candy.functionalSoftRed, candy.functionalSoftRedIcon),
        ink: candy.functionalSoftRedIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardRed,
      ),
      ChatPeerAccent(
        fill: _gum(candy.brand, candy.postShareIcon),
        ink: candy.postShareIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardBlue,
      ),
      ChatPeerAccent(
        fill: _gum(candy.infoSoft, candy.functionalSoftBlueIcon),
        ink: candy.functionalSoftBlueIcon,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardBlue,
      ),
      ChatPeerAccent(
        fill: _gum(candy.activeColor, candy.primary),
        ink: candy.primary,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardGreen,
      ),
      ChatPeerAccent(
        fill: _gum(candy.bgSoftMint, candy.primary),
        ink: candy.primary,
        onFill: candy.textColor,
        meta: candy.subTextColor,
        border: candy.borderCardGreen,
      ),
    ];

    return slots[_stableIndex(seed) % slots.length];
  }

  static int _stableIndex(String seed) {
    final raw = seed.trim();
    if (raw.isEmpty) return 0;
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
