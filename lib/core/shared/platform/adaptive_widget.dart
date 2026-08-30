import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/platform/app_platform.dart';
import 'package:flutter/widgets.dart';

/// База для переиспользуемых виджетов в `core/shared`.
///
/// При создании любого shared UI:
/// 1. Тема — цвета только через [AppColorsContext.colors] / [AppPalette] (light/dark).
/// 2. Платформа — разный нативный вид (Material / Cupertino).
///
/// ```dart
/// class AppFoo extends AdaptiveStatelessWidget {
///   const AppFoo({super.key});
///
///   @override
///   Widget buildMaterial(BuildContext context, AppPalette colors) {
///     // Android
///   }
///
///   @override
///   Widget buildCupertino(BuildContext context, AppPalette colors) {
///     // iOS
///   }
/// }
/// ```
abstract class AdaptiveStatelessWidget extends StatelessWidget {
  const AdaptiveStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return switch (AppPlatform.current) {
      AppPlatformType.ios => buildCupertino(context, colors),
      AppPlatformType.android => buildMaterial(context, colors),
    };
  }

  /// Android / Material.
  Widget buildMaterial(BuildContext context, AppPalette colors);

  /// iOS / Cupertino.
  Widget buildCupertino(BuildContext context, AppPalette colors);
}
