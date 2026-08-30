import 'dart:math' as math;

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/presentation/theme/onboarding_colors.dart';
import 'package:flutter/material.dart';

/// Анимированная иллюстрация слайда — эмодзи + палитра Clover.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    super.key,
    required this.kind,
    required this.active,
  });

  final OnboardingIllustrationKind kind;
  final bool active;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant OnboardingIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = context.widthByContext(300).clamp(240.0, 340.0);

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return switch (widget.kind) {
            OnboardingIllustrationKind.welcome => _WelcomeArt(t: t),
            OnboardingIllustrationKind.feedMap => _FeedMapArt(t: t),
            OnboardingIllustrationKind.create => _CreateArt(t: t),
            OnboardingIllustrationKind.chat => _ChatArt(t: t),
            OnboardingIllustrationKind.profile => _ProfileArt(t: t),
            OnboardingIllustrationKind.services => _ServicesArt(t: t),
          };
        },
      ),
    );
  }
}

double _wave(double t, {double phase = 0, double amp = 1}) {
  return math.sin((t * math.pi * 2) + phase) * amp;
}

class _ColorDisc extends StatelessWidget {
  const _ColorDisc({
    required this.colors,
    required this.child,
  });

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            colors[0].withValues(alpha: 0.28),
            colors[1].withValues(alpha: 0.22),
            colors[2].withValues(alpha: 0.26),
            colors[0].withValues(alpha: 0.28),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: palette.shadowDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surface.withValues(alpha: 0.78),
        ),
        child: child,
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.color,
    required this.size,
  });

  final String emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: palette.shadowDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.42)),
    );
  }
}

class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final pulse = 1.0 + _wave(t, amp: 0.04);

    return _ColorDisc(
      colors: const [
        OnboardingColors.cloverGreen,
        OnboardingColors.softBlue,
        OnboardingColors.lavender,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: pulse,
            child: const Text('🍀', style: TextStyle(fontSize: 78)),
          ),
          Positioned(
            top: 40 + _wave(t, phase: 0.4, amp: 7),
            left: 42,
            child: _EmojiChip(
              emoji: '🗺️',
              color: OnboardingColors.softBlue,
              size: 56,
            ),
          ),
          Positioned(
            bottom: 44 + _wave(t, phase: 1.2, amp: 6),
            right: 40,
            child: _EmojiChip(
              emoji: '💼',
              color: OnboardingColors.lavender,
              size: 52,
            ),
          ),
          Positioned(
            top: 56 + _wave(t, phase: 2.0, amp: 5),
            right: 48,
            child: _EmojiChip(
              emoji: '🎉',
              color: OnboardingColors.warmYellow,
              size: 44,
            ),
          ),
          Positioned(
            bottom: 56 + _wave(t, phase: 2.6, amp: 4),
            left: 50,
            child: _EmojiChip(
              emoji: '🩷',
              color: OnboardingColors.coralPink,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMapArt extends StatelessWidget {
  const _FeedMapArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final morph = (0.5 + 0.5 * _wave(t, phase: 0.15)).clamp(0.0, 1.0);
    final palette = context.colors;

    return _ColorDisc(
      colors: const [
        OnboardingColors.softBlue,
        OnboardingColors.cloverGreen,
        OnboardingColors.lavender,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - morph * 0.45,
            child: Transform.translate(
              offset: Offset(-30 * morph, _wave(t, amp: 3)),
              child: _EmojiChip(
                emoji: '📰',
                color: OnboardingColors.cloverGreen,
                size: 78,
              ),
            ),
          ),
          Opacity(
            opacity: 0.5 + morph * 0.5,
            child: Transform.translate(
              offset: Offset(30 * (1 - morph), -_wave(t, phase: 1, amp: 3)),
              child: _EmojiChip(
                emoji: '🗺️',
                color: OnboardingColors.softBlue,
                size: 78,
              ),
            ),
          ),
          Positioned(
            bottom: 52 + _wave(t, amp: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: OnboardingColors.lavender.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: OnboardingColors.lavender.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '✨ ×2 Home',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateArt extends StatelessWidget {
  const _CreateArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final pop = 0.92 + 0.08 * (0.5 + 0.5 * _wave(t, phase: 0.8));

    return _ColorDisc(
      colors: const [
        OnboardingColors.coralPink,
        OnboardingColors.warmYellow,
        OnboardingColors.softBlue,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: pop,
            child: _EmojiChip(
              emoji: '📌',
              color: OnboardingColors.coralPink,
              size: 84,
            ),
          ),
          Positioned(
            top: 46 + _wave(t, phase: 0.5, amp: 6),
            right: 40,
            child: _EmojiChip(
              emoji: '📸',
              color: OnboardingColors.softBlue,
              size: 50,
            ),
          ),
          Positioned(
            bottom: 48 + _wave(t, phase: 1.6, amp: 5),
            left: 40,
            child: _EmojiChip(
              emoji: '💬',
              color: OnboardingColors.warmYellow,
              size: 50,
            ),
          ),
          Positioned(
            top: 54 + _wave(t, phase: 2.1, amp: 4),
            left: 48,
            child: _EmojiChip(
              emoji: '❤️',
              color: OnboardingColors.coralPink,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatArt extends StatelessWidget {
  const _ChatArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return _ColorDisc(
      colors: const [
        OnboardingColors.softBlue,
        OnboardingColors.lavender,
        OnboardingColors.coralPink,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(_wave(t, amp: 4), _wave(t, phase: 0.8, amp: 3)),
            child: _EmojiChip(
              emoji: '💬',
              color: OnboardingColors.softBlue,
              size: 86,
            ),
          ),
          Positioned(
            top: 48 + _wave(t, phase: 0.4, amp: 5),
            left: 44,
            child: _EmojiChip(
              emoji: '👋',
              color: OnboardingColors.warmYellow,
              size: 48,
            ),
          ),
          Positioned(
            bottom: 50 + _wave(t, phase: 1.5, amp: 5),
            right: 42,
            child: _EmojiChip(
              emoji: '⚡',
              color: OnboardingColors.coralPink,
              size: 48,
            ),
          ),
          Positioned(
            top: 58 + _wave(t, phase: 2.2, amp: 4),
            right: 50,
            child: _EmojiChip(
              emoji: '💜',
              color: OnboardingColors.lavender,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileArt extends StatelessWidget {
  const _ProfileArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final pulse = 1.0 + _wave(t, amp: 0.03);

    return _ColorDisc(
      colors: const [
        OnboardingColors.coralPink,
        OnboardingColors.cloverGreen,
        OnboardingColors.lavender,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: pulse,
            child: _EmojiChip(
              emoji: '👤',
              color: OnboardingColors.cloverGreen,
              size: 86,
            ),
          ),
          Positioned(
            top: 46 + _wave(t, phase: 0.5, amp: 5),
            right: 42,
            child: _EmojiChip(
              emoji: '📸',
              color: OnboardingColors.softBlue,
              size: 48,
            ),
          ),
          Positioned(
            bottom: 48 + _wave(t, phase: 1.4, amp: 5),
            left: 42,
            child: _EmojiChip(
              emoji: '🌟',
              color: OnboardingColors.warmYellow,
              size: 48,
            ),
          ),
          Positioned(
            top: 56 + _wave(t, phase: 2.0, amp: 4),
            left: 48,
            child: _EmojiChip(
              emoji: '🛍️',
              color: OnboardingColors.coralPink,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesArt extends StatelessWidget {
  const _ServicesArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return _ColorDisc(
      colors: const [
        OnboardingColors.warmYellow,
        OnboardingColors.lavender,
        OnboardingColors.cloverGreen,
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 40 + _wave(t, amp: 5),
            child: Transform.rotate(
              angle: _wave(t, phase: 0.3, amp: 0.07),
              child: _EmojiChip(
                emoji: '📅',
                color: OnboardingColors.cloverGreen,
                size: 78,
              ),
            ),
          ),
          Positioned(
            right: 40 + _wave(t, phase: 1.1, amp: 5),
            child: Transform.rotate(
              angle: -_wave(t, phase: 0.9, amp: 0.07),
              child: _EmojiChip(
                emoji: '⭐',
                color: OnboardingColors.warmYellow,
                size: 78,
              ),
            ),
          ),
          Positioned(
            bottom: 48 + _wave(t, phase: 1.8, amp: 4),
            child: _EmojiChip(
              emoji: '💜',
              color: OnboardingColors.lavender,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}
