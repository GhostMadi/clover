import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/resources.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/auth/shared/presentation/widget/auth_social_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().loginWithPassword(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthCubit, bool>((c) => c.state is AuthLoading);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is AuthError,
      listener: (context, state) {
        if (state is! AuthError) return;
        AppSnackBar.show(
          context,
          message: AuthErrorMessages.messageFor(state.code),
          kind: AppSnackBarKind.error,
        );
      },
      child: Scaffold(
        backgroundColor: context.colors.bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.widthByContext(32),
              context.heightByContext(40),
              context.widthByContext(32),
              context.heightByContext(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppImages.logo, height: context.heightByContext(40)),
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
                SizedBox(height: context.heightByContext(40)),
                AppField(
                  controller: _identifierController,
                  labelText: 'Ник или email',
                  hintText: '@username или email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isEnabled: !isLoading,
                ),
                const SizedBox(height: 14),
                AppField(
                  controller: _passwordController,
                  labelText: 'Пароль',
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  isEnabled: !isLoading,
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Text(
                      _obscurePassword ? 'Показать' : 'Скрыть',
                      style: AppTextStyle.base(
                        12,
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : () => context.router.push(const ForgotPasswordRoute()),
                    child: Text(
                      'Забыли пароль?',
                      style: AppTextStyle.base(
                        13,
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.white),
                          )
                        : Text(
                            'Войти',
                            style: AppTextStyle.base(
                              15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Нет аккаунта?', style: AppTextStyle.base(14, color: context.colors.subTextColor)),
                    TextButton(
                      onPressed: isLoading ? null : () => context.router.push(const RegisterEmailRoute()),
                      child: Text(
                        'Создать',
                        style: AppTextStyle.base(
                          14,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightByContext(28)),
                const AuthOrDivider(),
                SizedBox(height: context.heightByContext(24)),
                const AuthGoogleSignInButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
