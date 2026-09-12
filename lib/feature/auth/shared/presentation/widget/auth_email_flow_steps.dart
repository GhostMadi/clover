import 'dart:async';

import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_messages.dart';
import 'package:clover/core/auth/repositories/auth_repository.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthEmailStep extends StatelessWidget {
  const AuthEmailStep({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.hint,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final bool isLoading;
  final String hint;
  final String buttonLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(hint, style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35)),
        const SizedBox(height: 16),
        AppField(
          controller: emailController,
          labelText: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          isEnabled: !isLoading,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                    buttonLabel,
                    style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

class AuthOtpStep extends StatefulWidget {
  const AuthOtpStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.isLoading,
    required this.onResend,
    required this.onVerify,
    this.resendCooldown = Duration.zero,
  });

  final String email;
  final TextEditingController otpController;
  final bool isLoading;

  /// `null` — ок; иначе код ошибки (шаг OTP не сбрасываем).
  final Future<AuthErrorCode?> Function() onResend;
  final VoidCallback onVerify;
  /// Optional optimistic lock before [AuthCubit.emailOtpRetryAfterSeconds] bootstrap.
  final Duration resendCooldown;

  @override
  State<AuthOtpStep> createState() => _AuthOtpStepState();
}

class _AuthOtpStepState extends State<AuthOtpStep> {
  Timer? _ticker;
  DateTime _resendAvailableAt = DateTime.now();
  bool _bootstrapping = true;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _resendAvailableAt = DateTime.now().add(widget.resendCooldown);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapCooldown());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapCooldown() async {
    final left = await context.read<AuthCubit>().emailOtpRetryAfterSeconds(widget.email);
    if (!mounted) return;
    setState(() => _bootstrapping = false);
    if (left > 0) {
      _startCooldown(Duration(seconds: left));
    } else {
      _resendAvailableAt = DateTime.now();
      setState(() {});
    }
  }

  void _startCooldown(Duration duration) {
    _ticker?.cancel();
    _resendAvailableAt = DateTime.now().add(duration);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_isCoolingDown) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
    setState(() {});
  }

  bool get _isCoolingDown => DateTime.now().isBefore(_resendAvailableAt);

  int get _secondsLeft {
    final left = _resendAvailableAt.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  String get _countdownLabel {
    final total = _secondsLeft;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _resend() async {
    if (widget.isLoading || _resending || _isCoolingDown || _bootstrapping) return;
    setState(() => _resending = true);
    final code = await widget.onResend();
    if (!mounted) return;

    final left = await context.read<AuthCubit>().emailOtpRetryAfterSeconds(widget.email);
    if (!mounted) return;

    setState(() => _resending = false);

    if (code != null) {
      AppSnackBar.show(
        context,
        message: AuthErrorMessages.messageFor(code, retryAfterSeconds: left > 0 ? left : null),
        kind: AppSnackBarKind.error,
      );
    }

    if (left > 0) {
      _startCooldown(Duration(seconds: left));
    } else if (code == null) {
      _startCooldown(widget.resendCooldown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cooling = _bootstrapping || _isCoolingDown;
    final busy = widget.isLoading || _resending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Код отправлен на ${widget.email}',
          style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Письмо с welcome@clover.com.kz',
          style: AppTextStyle.base(13, color: context.colors.subTextColor),
        ),
        const SizedBox(height: 16),
        AppField(
          controller: widget.otpController,
          labelText: 'Код из письма',
          hintText: '123456',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          isEnabled: !busy,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: busy ? null : widget.onVerify,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.white),
                  )
                : Text(
                    'Подтвердить',
                    style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.white),
                  ),
          ),
        ),
        if (cooling)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _bootstrapping ? 'Проверяем…' : 'Повторная отправка через $_countdownLabel',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: context.colors.subTextColor),
            ),
          )
        else
          TextButton(
            onPressed: busy ? null : _resend,
            child: Text(
              'Отправить код снова',
              style: AppTextStyle.base(13, color: context.colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class AuthPasswordStep extends StatelessWidget {
  const AuthPasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.isLoading,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final String title;
  final String subtitle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyle.base(18, fontWeight: FontWeight.w700, color: context.colors.textColor),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35)),
        const SizedBox(height: 16),
        AppField(
          controller: passwordController,
          labelText: 'Пароль',
          hintText: 'минимум ${AuthRepository.minPasswordLength} символов',
          obscureText: true,
          textInputAction: TextInputAction.next,
          isEnabled: !isLoading,
        ),
        const SizedBox(height: 14),
        AppField(
          controller: confirmController,
          labelText: 'Повтор пароля',
          hintText: '••••••••',
          obscureText: true,
          textInputAction: TextInputAction.done,
          isEnabled: !isLoading,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                    'Сохранить пароль',
                    style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
