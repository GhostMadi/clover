import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';

enum AppSnackBarKind { info, success, error }

/// Топовое уведомление (как in-app notification), не системный SnackBar.
///
/// - Появляется сверху через [Overlay]
/// - Закрывается по таймеру, по тапу, или свайпом вверх
/// - Реагирует на drag естественно (следует за пальцем)
abstract final class AppSnackBar {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarKind kind = AppSnackBarKind.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    hide();

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (ctx) {
        return _AppTopSnack(title: title, message: message, kind: kind, onTap: onTap, onDismiss: hide);
      },
    );
    overlay.insert(_entry!);

    _timer = Timer(duration, () {
      hide();
    });
  }
}

class _AppTopSnack extends StatefulWidget {
  const _AppTopSnack({
    required this.title,
    required this.message,
    required this.kind,
    required this.onTap,
    required this.onDismiss,
  });

  final String? title;
  final String message;
  final AppSnackBarKind kind;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  @override
  State<_AppTopSnack> createState() => _AppTopSnackState();
}

class _AppTopSnackState extends State<_AppTopSnack> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _appear;

  double _dragDy = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _appear = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _c.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final (accent, icon) = switch (widget.kind) {
      AppSnackBarKind.success => (AppColors.primary, Icons.check_circle_outline_rounded),
      AppSnackBarKind.error => (AppColors.destructive, Icons.error_outline_rounded),
      AppSnackBarKind.info => (AppColors.primary, Icons.info_outline_rounded),
    };

    final safeTop = MediaQuery.paddingOf(context).top;
    final yDrag = _dragDy.clamp(-200.0, 0.0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _appear,
              builder: (context, child) {
                // стартует чуть выше и плавно спускается
                final baseY = (-24.0) * (1.0 - _appear.value);
                return Transform.translate(
                  offset: Offset(0, baseY + yDrag),
                  child: Opacity(opacity: _appear.value, child: child),
                );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, safeTop > 0 ? 6 : 10, 12, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.onTap?.call();
                    _close();
                  },
                  onVerticalDragUpdate: (d) {
                    setState(() {
                      _dragDy = (_dragDy + d.delta.dy).clamp(-220.0, 220.0);
                    });
                  },
                  onVerticalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    final shouldDismiss = _dragDy < -48 || v < -650;
                    if (shouldDismiss) {
                      _close();
                    } else {
                      setState(() => _dragDy = 0);
                    }
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          type: MaterialType.transparency,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.9)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowDark.withValues(alpha: 0.10),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
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
                                              color: AppColors.textColor,
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
                                            color: AppColors.textColor.withValues(alpha: 0.92),
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ),
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
