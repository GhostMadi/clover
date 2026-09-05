import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

enum AppSnackBarKind { info, success, error }

enum AppSnackBarPlacement { top, center }

/// Топовое / центрированное уведомление (не системный SnackBar).
///
/// - Появляется через [Overlay] с плавным slide + fade + soft scale
/// - Закрывается по таймеру, тапу или свайпу
/// - Drag с резиновой натяжкой и spring-возвратом
abstract final class AppSnackBar {
  static OverlayEntry? _entry;
  static Timer? _timer;
  static Future<void> Function()? _animatedClose;

  static void hide({bool animated = false}) {
    _timer?.cancel();
    _timer = null;

    if (animated && _animatedClose != null) {
      unawaited(_animatedClose!());
      return;
    }

    _animatedClose = null;
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarKind kind = AppSnackBarKind.info,
    AppSnackBarPlacement placement = AppSnackBarPlacement.top,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    hide(animated: false);

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (ctx) {
        return _AppTopSnack(
          title: title,
          message: message,
          kind: kind,
          placement: placement,
          onTap: onTap,
          onDismiss: () {
            _animatedClose = null;
            _timer?.cancel();
            _timer = null;
            _entry?.remove();
            _entry = null;
          },
          onReady: (close) => _animatedClose = close,
          onInteractionChanged: (active) {
            if (active) {
              _timer?.cancel();
              _timer = null;
            } else if (_entry != null) {
              _timer?.cancel();
              _timer = Timer(duration, () => hide(animated: true));
            }
          },
        );
      },
    );
    overlay.insert(_entry!);

    _timer = Timer(duration, () => hide(animated: true));
  }
}

class _AppTopSnack extends StatefulWidget {
  const _AppTopSnack({
    required this.title,
    required this.message,
    required this.kind,
    required this.placement,
    required this.onTap,
    required this.onDismiss,
    required this.onReady,
    required this.onInteractionChanged,
  });

  final String? title;
  final String message;
  final AppSnackBarKind kind;
  final AppSnackBarPlacement placement;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final void Function(Future<void> Function() close) onReady;
  final void Function(bool active) onInteractionChanged;

  @override
  State<_AppTopSnack> createState() => _AppTopSnackState();
}

class _AppTopSnackState extends State<_AppTopSnack> with TickerProviderStateMixin {
  static const _enterMs = 420;
  static const _exitMs = 280;
  static const _dismissThreshold = -42.0;
  static const _dismissVelocity = -700.0;

  late final AnimationController _appear;
  late final AnimationController _drag;
  late final Animation<double> _appearT;

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _enterMs),
      reverseDuration: const Duration(milliseconds: _exitMs),
    );
    _appearT = CurvedAnimation(parent: _appear, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    _drag = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    widget.onReady(_close);
    _appear.forward();
  }

  @override
  void dispose() {
    _appear.dispose();
    _drag.dispose();
    super.dispose();
  }

  double get _dragDy => _drag.value;

  /// Вниз — резиновая натяжка; вверх — почти 1:1 для свайпа закрытия.
  double get _visualDrag {
    final dy = _dragDy;
    if (dy >= 0) {
      // rubber-band: чем дальше тянешь вниз, тем сильнее сопротивление
      return 28 * math.log(1 + dy / 28);
    }
    return dy;
  }

  Future<void> _close({double? flingVelocity}) async {
    if (_closing) return;
    _closing = true;
    widget.onInteractionChanged(false);

    final start = _dragDy;
    final target = -140.0;
    final v = flingVelocity ?? 0;

    // Улетает вверх вместе с fade/scale
    unawaited(
      _drag.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 220, damping: 22),
          start,
          target,
          v.clamp(-2400.0, 0.0),
        ),
      ),
    );

    await _appear.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  void _onDragStart(DragStartDetails _) {
    if (_closing) return;
    widget.onInteractionChanged(true);
    _drag.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_closing) return;
    _drag.value = (_drag.value + d.delta.dy).clamp(-240.0, 160.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_closing) return;

    final v = d.primaryVelocity ?? 0;
    final shouldDismiss = _dragDy < _dismissThreshold || v < _dismissVelocity;
    if (shouldDismiss) {
      unawaited(_close(flingVelocity: v));
      return;
    }

    // Пружинный возврат на место
    final from = _dragDy;
    _drag
        .animateWith(
          SpringSimulation(
            const SpringDescription(mass: 0.85, stiffness: 260, damping: 20),
            from,
            0,
            v.clamp(-1200.0, 1200.0),
          ),
        )
        .whenComplete(() {
          if (!mounted || _closing) return;
          widget.onInteractionChanged(false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (accent, icon) = switch (widget.kind) {
      AppSnackBarKind.success => (colors.primary, AppIcons.checkCircleOutline.icon),
      AppSnackBarKind.error => (colors.destructive, AppIcons.errorOutline.icon),
      AppSnackBarKind.info => (colors.primary, AppIcons.infoOutline.icon),
    };

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: _closing && _appear.value < 0.05,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: Listenable.merge([_appearT, _drag]),
              builder: (context, child) {
                final t = _appearT.value;
                final slideIn = (1.0 - t) * -56.0;
                final scale = 0.92 + (0.08 * t);
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, slideIn + _visualDrag),
                    child: Transform.scale(scale: scale, alignment: Alignment.topCenter, child: child),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_closing) return;
                    widget.onTap?.call();
                    unawaited(_close());
                  },
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  onVerticalDragCancel: () {
                    if (_closing) return;
                    _onDragEnd(DragEndDetails(primaryVelocity: 0));
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Material(
                          type: MaterialType.transparency,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.borderSoft.withValues(alpha: 0.9)),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadowDark.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.14),
                                    ),
                                    child: Icon(icon, size: 16, color: accent),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (widget.title != null && widget.title!.trim().isNotEmpty) ...[
                                          Text(
                                            widget.title!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyle.base(
                                              13,
                                              color: colors.textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                        ],
                                        Text(
                                          widget.message,
                                          maxLines: widget.title == null ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyle.base(
                                            13,
                                            color: colors.textColor.withValues(alpha: 0.92),
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
