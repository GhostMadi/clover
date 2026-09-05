import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/auth/repositories/auth_repository.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/auth/shared/presentation/widget/auth_email_flow_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _SettingsPasswordMode { set, reset }

enum _ResetStep { sendCode, otp, newPassword }

@RoutePage()
class SettingsPasswordPage extends StatefulWidget {
  const SettingsPasswordPage({super.key});

  @override
  State<SettingsPasswordPage> createState() => _SettingsPasswordPageState();
}

class _SettingsPasswordPageState extends State<SettingsPasswordPage> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loadingFlag = true;
  bool _busy = false;
  String? _errorText;
  _SettingsPasswordMode? _mode;
  _ResetStep _resetStep = _ResetStep.sendCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMode());
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadMode() async {
    setState(() {
      _loadingFlag = true;
      _errorText = null;
    });
    try {
      final hasPassword = await context.read<AuthCubit>().currentUserHasPassword();
      if (!mounted) return;
      setState(() {
        _mode = hasPassword ? _SettingsPasswordMode.reset : _SettingsPasswordMode.set;
        _loadingFlag = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingFlag = false;
        _errorText = AuthErrorMessages.messageFor(AuthErrorCode.unknown);
      });
    }
  }

  Future<void> _saveSetPassword() async {
    if (_busy) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.trim().length < AuthRepository.minPasswordLength) {
      setState(() => _errorText = AuthErrorMessages.messageFor(AuthErrorCode.passwordInvalid));
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = AuthErrorMessages.messageFor(AuthErrorCode.passwordMismatch));
      return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });
    final error = await context.read<AuthCubit>().updateSessionPassword(password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _errorText = AuthErrorMessages.messageFor(error);
      });
      return;
    }
    setState(() => _busy = false);
    _toast('Пароль установлен');
    await context.router.maybePop();
  }

  Future<void> _sendResetOtp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final cubit = context.read<AuthCubit>();
    final error = await cubit.sendSessionResetPasswordOtp();
    if (!mounted) return;
    if (error != null) {
      final email = cubit.currentUserEmail() ?? '';
      final left = email.isEmpty ? 0 : await cubit.emailOtpRetryAfterSeconds(email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = AuthErrorMessages.messageFor(
          error,
          retryAfterSeconds: left > 0 ? left : null,
        );
      });
      return;
    }
    final email = cubit.currentUserEmail() ?? '';
    final left = email.isEmpty ? 0 : await cubit.emailOtpRetryAfterSeconds(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _resetStep = _ResetStep.otp;
      _errorText = null;
    });
    if (left > 0) {
      // Либо только что отправили, либо кулдаун: в обоих случаях код уже на почте.
      AppSnackBar.show(
        context,
        message: 'Введите код из письма',
        kind: AppSnackBarKind.info,
      );
    }
  }

  Future<AuthErrorCode?> _resendResetOtp() =>
      context.read<AuthCubit>().sendSessionResetPasswordOtp();

  Future<void> _verifyResetOtp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final error = await context.read<AuthCubit>().verifySessionResetPasswordOtp(_otpController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _errorText = AuthErrorMessages.messageFor(error);
      });
      return;
    }
    setState(() {
      _busy = false;
      _resetStep = _ResetStep.newPassword;
    });
  }

  Future<void> _saveResetPassword() async {
    if (_busy) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.trim().length < AuthRepository.minPasswordLength) {
      setState(() => _errorText = AuthErrorMessages.messageFor(AuthErrorCode.passwordInvalid));
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = AuthErrorMessages.messageFor(AuthErrorCode.passwordMismatch));
      return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });
    final error = await context.read<AuthCubit>().updateSessionPassword(password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _errorText = AuthErrorMessages.messageFor(error);
      });
      return;
    }
    setState(() => _busy = false);
    _toast('Пароль сброшен');
    await context.router.maybePop();
  }

  void _toast(String text, {AppSnackBarKind kind = AppSnackBarKind.success}) {
    AppSnackBar.show(context, message: text, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _SettingsPasswordMode.reset => 'Сбросить пароль',
      _SettingsPasswordMode.set => 'Установить пароль',
      null => 'Пароль',
    };

    return SettingsScreenShell(
      title: title,
      body: _loadingFlag
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_mode == _SettingsPasswordMode.set) _buildSetBody(),
                  if (_mode == _SettingsPasswordMode.reset) _buildResetBody(),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: AppTextStyle.base(13, color: context.colors.error, height: 1.35),
                    ),
                  ],
                  SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
                ],
              ),
            ),
    );
  }

  Widget _buildSetBody() {
    return AuthPasswordStep(
      passwordController: _passwordController,
      confirmController: _confirmController,
      isLoading: _busy,
      title: 'Пароль для входа',
      subtitle: 'Нужен, если входили через Google — потом можно входить и по паролю.',
      onSubmit: _saveSetPassword,
    );
  }

  Widget _buildResetBody() {
    final email = context.read<AuthCubit>().currentUserEmail() ?? '';

    return switch (_resetStep) {
      _ResetStep.sendCode => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Сброс пароля',
              style: AppTextStyle.base(18, fontWeight: FontWeight.w700, color: context.colors.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              email.isEmpty
                  ? 'У аккаунта нет email — сброс по коду недоступен.'
                  : 'Отправим код на $email. После подтверждения зададите новый пароль.',
              style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: (_busy || email.isEmpty) ? null : _sendResetOtp,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.white),
                      )
                    : Text(
                        'Отправить код',
                        style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.white),
                      ),
              ),
            ),
          ],
        ),
      _ResetStep.otp => AuthOtpStep(
          email: email,
          otpController: _otpController,
          isLoading: _busy,
          onResend: _resendResetOtp,
          onVerify: _verifyResetOtp,
        ),
      _ResetStep.newPassword => AuthPasswordStep(
          passwordController: _passwordController,
          confirmController: _confirmController,
          isLoading: _busy,
          title: 'Новый пароль',
          subtitle: 'Придумайте новый пароль для входа.',
          onSubmit: _saveResetPassword,
        ),
    };
  }
}
