import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:clover/core/shared/switchable_stack.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_home_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/cubit/dashboard_home_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Первый таб дашборда: лента ивентов или карта без пересоздания остальных табов.
@RoutePage()
class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<DashboardHomeModeCubit>().state;

    return JellyBounce(
      trigger: mode,
      child: SwitchableStackByKey(active: mode, variants: DashboardHomeTabConfig.variants),
    );
  }
}
