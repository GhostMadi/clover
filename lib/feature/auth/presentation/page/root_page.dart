import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/deep_link/app_deep_link_service.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<void> _routeAuthenticated(BuildContext context, String userId) async {
    final seen = await sl<OnboardingStore>().hasSeen(userId, OnboardingCatalog.appV1Id);
    if (!context.mounted) return;
    if (seen) {
      await AutoRouter.of(context).replaceAll([const AppDashboardRoute()]);
      if (context.mounted) {
        await sl<AppDeepLinkService>().flushPending();
      }
      return;
    }
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
          case Unauthenticated():
            router.replaceAll([const LoginRoute()]);
          case AuthError() || AuthEmailOtpSent() || AuthPasswordSetupRequired():
            break;
          default:
            break;
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (previous, current) {
          // Не перекрываем login/register splash'ем при каждой отправке OTP.
          if (current is AuthLoading && previous is! AuthInitial) return false;
          return true;
        },
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
      backgroundColor: context.colors.pageBackground,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
        ),
      ),
    );
  }
}
