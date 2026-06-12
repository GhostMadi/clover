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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is! AuthLoading,
      listener: (context, state) {
        final router = AutoRouter.of(context);

        switch (state) {
          case Authenticated():
            router.replaceAll([const AppDashboardRoute()]);
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
    return const Scaffold(
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
