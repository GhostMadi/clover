import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<void> _routeAuthenticated(BuildContext context, String userId) async {
    // TODO: вернуть hasSeen(userId, OnboardingCatalog.appV1Id), когда онбординг стабилизируем.
    if (!context.mounted) return;
    await AutoRouter.of(context).replaceAll([OnboardingRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is! AuthLoading,
      listener: (context, state) {
        final router = AutoRouter.of(context);

        switch (state) {
          case Authenticated(:final user):
            unawaited(_routeAuthenticated(context, user.id));
          case Unauthenticated() || AuthError():
            router.replaceAll([const LoginRoute()]);
          default:
            break;
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthInitial() || AuthLoading() => const _AuthSplash(),
            _ => const AutoRouter(),
          };
        },
      ),
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}
