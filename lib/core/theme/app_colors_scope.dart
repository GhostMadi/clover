import 'package:clover/core/theme/app_color_binding.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Inherited host: dependents of [AppColorsScope.of] rebuild on each theme lerp frame.
class AppColorsScope extends InheritedWidget {
  const AppColorsScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final AppPalette palette;

  static AppPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppColorsScope>();
    if (scope != null) return scope.palette;
    return Theme.of(context).extension<AppPalette>() ?? AppColorBinding.palette;
  }

  @override
  bool updateShouldNotify(AppColorsScope oldWidget) => oldWidget.palette != palette;
}

extension AppColorsContext on BuildContext {
  AppPalette get colors => AppColorsScope.of(this);
}

/// Forces the whole subtree to rebuild when [palette] changes.
///
/// Needed because most widgets still read `AppColors.token` via static getters
/// (no Theme/Inherited dependency). [State] is preserved — navigation stays intact.
class AppThemeTreeRebuilder extends StatefulWidget {
  const AppThemeTreeRebuilder({
    super.key,
    required this.palette,
    required this.child,
  });

  final AppPalette palette;
  final Widget child;

  @override
  State<AppThemeTreeRebuilder> createState() => _AppThemeTreeRebuilderState();
}

class _AppThemeTreeRebuilderState extends State<AppThemeTreeRebuilder> {
  @override
  void didUpdateWidget(covariant AppThemeTreeRebuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_paletteVisuallyEquals(oldWidget.palette, widget.palette)) {
      _scheduleSubtreeRebuild();
    }
  }

  bool _paletteVisuallyEquals(AppPalette a, AppPalette b) {
    return a.brightness == b.brightness &&
        a.pageBackground == b.pageBackground &&
        a.surface == b.surface &&
        a.textColor == b.textColor &&
        a.subTextColor == b.subTextColor &&
        a.border == b.border &&
        a.primary == b.primary &&
        a.surfaceMuted == b.surfaceMuted &&
        a.surfaceSoft == b.surfaceSoft &&
        a.iconMuted == b.iconMuted;
  }

  void _scheduleSubtreeRebuild() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markNeedsBuildRecursive(context as Element);
    });
  }

  void _markNeedsBuildRecursive(Element element) {
    element.visitChildren((child) {
      child.markNeedsBuild();
      _markNeedsBuildRecursive(child);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
