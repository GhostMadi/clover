import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/resources.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final errorCode = switch (context.watch<AuthCubit>().state) {
      AuthError(:final code) => code,
      _ => null,
    };

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is AuthError,
      listener: (context, state) {
        if (state is! AuthError) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AuthErrorMessages.messageFor(state.code)),
              backgroundColor: context.colors.shadowDark.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
        backgroundColor: context.colors.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              SizedBox(height: context.heightByContext(12)),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.logo,
                    height: context.heightByContext(40),
                  ),
                  SizedBox(width: context.widthByContext(12)),

                  Text(
                    'Clover',
                    style: AppTextStyle.base(
                      context.heightByContext(32),
                      fontWeight: FontWeight.w600,
                      color: context.colors.activeColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.heightByContext(12)),

              if (errorCode != null) ...[
                SizedBox(height: context.heightByContext(20)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.widthByContext(40),
                  ),
                  child: Text(
                    AuthErrorMessages.messageFor(errorCode),
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(
                      context.heightByContext(13),
                      color: context.colors.error,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 4),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthByContext(32),
                ),
                child: const _AuthDivider(),
              ),

              SizedBox(height: context.heightByContext(28)),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthByContext(32),
                ),
                child: const _GoogleSignInButton(),
              ),

              SizedBox(height: context.heightByContext(48)),
            ],
          ),
        ),
      ),
    );
  }
}class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: context.colors.border,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.widthByContext(16),
          ),
          child: Text(
            'or',
            style: AppTextStyle.base(
              context.heightByContext(12),
              color: context.colors.subTextColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: context.colors.border,
          ),
        ),
      ],
    );
  }
}class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<AuthCubit, bool>((c) => c.state is AuthLoading);

    return SizedBox(
      width: double.infinity,
      height: context.heightByContext(54),
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () => context.read<AuthCubit>().loginWithGoogle(),

        style: OutlinedButton.styleFrom(
          backgroundColor: context.colors.surface,
          disabledBackgroundColor: context.colors.surfaceMuted,
          side: BorderSide(
            color: context.colors.borderInput,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.widthByContext(14),
            ),
          ),
          foregroundColor: context.colors.textColor,
        ),

        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppSvg.google,
                    height: context.heightByContext(22),
                  ),
                  SizedBox(width: context.widthByContext(12)),
                  Text(
                    'Continue with Google',
                    style: AppTextStyle.base(
                      15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}