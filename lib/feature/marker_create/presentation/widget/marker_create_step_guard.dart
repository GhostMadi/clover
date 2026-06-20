import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// Возвращает на предыдущий шаг, если условие шага не выполнено.
class MarkerCreateStepGuard extends StatelessWidget {
  const MarkerCreateStepGuard({
    super.key,
    required this.canShow,
    required this.child,
  });

  final bool canShow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (canShow) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.router.maybePop();
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
