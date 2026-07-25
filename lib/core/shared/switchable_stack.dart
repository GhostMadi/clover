import 'package:flutter/material.dart';

/// Вариант контента для [SwitchableStackByKey].
class SwitchableVariant<T> {
  const SwitchableVariant({required this.key, required this.child});

  final T key;
  final Widget child;
}

/// Держит несколько виджетов в дереве и показывает один по индексу.
///
/// Состояние скрытых вкладок сохраняется (IndexedStack).
class SwitchableStack extends StatelessWidget {
  const SwitchableStack({
    super.key,
    required this.activeIndex,
    required this.children,
  }) : assert(activeIndex >= 0);

  final int activeIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return IndexedStack(
      index: activeIndex.clamp(0, children.length - 1),
      sizing: StackFit.expand,
      children: children,
    );
  }
}

/// [SwitchableStack] с выбором активного варианта по ключу [active].
class SwitchableStackByKey<T> extends StatelessWidget {
  const SwitchableStackByKey({
    super.key,
    required this.active,
    required this.variants,
  });

  final T active;
  final List<SwitchableVariant<T>> variants;

  @override
  Widget build(BuildContext context) {
    final index = variants.indexWhere((variant) => variant.key == active);

    return SwitchableStack(
      activeIndex: index < 0 ? 0 : index,
      children: [for (final variant in variants) variant.child],
    );
  }
}
