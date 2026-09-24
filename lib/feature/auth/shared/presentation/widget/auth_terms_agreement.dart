import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Обязательное согласие с Terms / Privacy до входа или регистрации (App Store 1.2).
class AuthTermsAgreement extends StatefulWidget {
  const AuthTermsAgreement({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  static final Uri termsUri = Uri.parse('https://clover.com.kz/terms');
  static final Uri privacyUri = Uri.parse('https://clover.com.kz/privacy');

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  State<AuthTermsAgreement> createState() => _AuthTermsAgreementState();
}

class _AuthTermsAgreementState extends State<AuthTermsAgreement> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => launchUrl(AuthTermsAgreement.termsUri, mode: LaunchMode.externalApplication);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => launchUrl(AuthTermsAgreement.privacyUri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final linkStyle = AppTextStyle.base(
      13,
      color: colors.primary,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );
    final baseStyle = AppTextStyle.base(13, color: colors.subTextColor, height: 1.35);

    return InkWell(
      onTap: () => widget.onChanged(!widget.agreed),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.agreed ? AppIcons.checkBox.icon : AppIcons.checkBoxBlank.icon,
              size: 22,
              color: widget.agreed ? colors.primary : colors.iconMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: [
                    const TextSpan(text: 'Я соглашаюсь с '),
                    TextSpan(
                      text: 'условиями использования',
                      style: linkStyle,
                      recognizer: _termsTap,
                    ),
                    const TextSpan(text: ' и '),
                    TextSpan(
                      text: 'политикой конфиденциальности',
                      style: linkStyle,
                      recognizer: _privacyTap,
                    ),
                    const TextSpan(
                      text:
                          '. Неприемлемый контент и оскорбительное поведение не допускаются.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
