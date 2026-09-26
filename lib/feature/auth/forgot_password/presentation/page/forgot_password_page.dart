import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/auth/shared/presentation/widget/auth_email_flow_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Widget _body(AuthState state, bool isLoading) {
    if (state is AuthPasswordSetupRequired && state.purpose == AuthOtpPurpose.resetPassword) {
      return AuthPasswordStep(
        passwordController: _passwordController,
        confirmController: _passwordConfirmController,
        isLoading: isLoading,
        title: context.l10n.auth_forgot_new_password_title,
        subtitle: context.l10n.auth_forgot_new_password_subtitle,
        onSubmit: () {
          final password = _passwordController.text.trim();
          final confirm = _passwordConfirmController.text.trim();
          if (password != confirm) {
            AppSnackBar.show(
              context,
              message: context.l10n.auth_register_password_mismatch,
              kind: AppSnackBarKind.error,
            );
            return;
          }
          context.read<AuthCubit>().completePasswordSetup(password);
        },
      );
    }

    if (state is AuthEmailOtpSent && state.purpose == AuthOtpPurpose.resetPassword) {
      return AuthOtpStep(
        email: state.email,
        otpController: _otpController,
        isLoading: isLoading,
        onResend: () => context.read<AuthCubit>().resendResetPasswordEmailOtp(state.email),
        onVerify: () => context.read<AuthCubit>().verifyEmailOtp(
              email: state.email,
              token: _otpController.text,
              purpose: AuthOtpPurpose.resetPassword,
            ),
      );
    }

    return AuthEmailStep(
      emailController: _emailController,
      isLoading: isLoading,
      hint: context.l10n.auth_forgot_email_hint,
      buttonLabel: context.l10n.auth_forgot_send_code,
      onSubmit: () => context.read<AuthCubit>().sendResetPasswordEmailOtp(_emailController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final isLoading = state is AuthLoading;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthError ||
          (curr is AuthEmailOtpSent &&
              curr.resumedWithoutResend &&
              curr.purpose == AuthOtpPurpose.resetPassword),
      listener: (context, state) {
        if (state is AuthError) {
          AppSnackBar.show(
            context,
            message: AuthErrorMessages.messageFor(state.code, context.l10n, retryAfterSeconds: state.retryAfterSeconds,),
            kind: AppSnackBarKind.error,
          );
          return;
        }
        if (state is AuthEmailOtpSent && state.resumedWithoutResend) {
          AppSnackBar.show(
            context,
            message: context.l10n.auth_register_code_already_sent,
            kind: AppSnackBarKind.info,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.bgColor,
        appBar: AppBar(
          backgroundColor: context.colors.bgColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              context.read<AuthCubit>().backToUnauthenticated();
              context.router.maybePop();
            },
            icon: Icon(AppIcons.back.icon, color: context.colors.textColor, size: 22),
          ),
          title: Text(
            context.l10n.auth_forgot_title,
            style: AppTextStyle.base(17, fontWeight: FontWeight.w700, color: context.colors.textColor),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: _body(state, isLoading),
          ),
        ),
      ),
    );
  }
}
