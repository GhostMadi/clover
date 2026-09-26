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
import 'package:clover/feature/auth/shared/presentation/widget/auth_terms_agreement.dart';
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
  var _termsAgreed = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _requireTerms() {
    AppSnackBar.show(
      context,
      message: context.l10n.auth_login_terms_required,
      kind: AppSnackBarKind.info,
    );
  }

  void _login() {
    if (!_termsAgreed) {
      _requireTerms();
      return;
    }
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
          message: AuthErrorMessages.messageFor(state.code, context.l10n),
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
                  labelText: context.l10n.auth_login_identifier_label,
                  hintText: context.l10n.auth_login_identifier_hint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isEnabled: !isLoading,
                ),
                const SizedBox(height: 14),
                AppField(
                  controller: _passwordController,
                  labelText: context.l10n.common_password,
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  isEnabled: !isLoading,
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Text(
                      _obscurePassword ? context.l10n.common_show : context.l10n.common_hide,
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
                      context.l10n.auth_login_forgot_password,
                      style: AppTextStyle.base(
                        13,
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AuthTermsAgreement(
                  agreed: _termsAgreed,
                  onChanged: (v) => setState(() => _termsAgreed = v),
                ),
                const SizedBox(height: 16),
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
                            context.l10n.auth_login_submit,
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
                    Text(context.l10n.auth_login_no_account, style: AppTextStyle.base(14, color: context.colors.subTextColor)),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (!_termsAgreed) {
                                _requireTerms();
                                return;
                              }
                              context.router.push(const RegisterEmailRoute());
                            },
                      child: Text(
                        context.l10n.auth_login_create,
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
                AuthGoogleSignInButton(
                  enabled: _termsAgreed,
                  onDisabledTap: _requireTerms,
                ),
                SizedBox(height: context.heightByContext(12)),
                AuthAppleSignInButton(
                  enabled: _termsAgreed,
                  onDisabledTap: _requireTerms,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
