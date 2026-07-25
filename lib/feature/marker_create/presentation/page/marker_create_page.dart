import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:flutter/material.dart';

/// Устаревший маршрут: перенаправляет в единый флоу создания публикации.
@RoutePage()
class MarkerCreatePage extends StatefulWidget {
  const MarkerCreatePage({super.key});

  @override
  State<MarkerCreatePage> createState() => _MarkerCreatePageState();
}

class _MarkerCreatePageState extends State<MarkerCreatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.router.replace(const PostCreateRoute());
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
