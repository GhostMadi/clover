import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:flutter/material.dart';

/// Состояние экрана / секции для [AppState].
enum AppScreenState {
  loading,
  empty,
  error,
  content,
}

/// Раскладка [AppState].
enum AppStateVariant {
  /// Центрированный блок (вкладка, список).
  center,

  /// Компактный баннер (ошибка в шапке профиля, inline в сетке).
  inline,
}

/// Унифицированные состояния: загрузка, пусто, ошибка, контент.
class AppState extends StatelessWidget {
  const AppState({
    super.key,
    required this.state,
    required this.child,
    this.loadingMessage,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
    this.errorMessage,
    this.errorIcon,
    this.onRetry,
    this.retryLabel = 'Повторить',
    this.onEmptyAction,
    this.emptyActionLabel = 'Создать',
    this.variant = AppStateVariant.center,
    this.asSliver = false,
  });

  const AppState.content({super.key, required this.child})
      : state = AppScreenState.content,
        loadingMessage = null,
        emptyTitle = null,
        emptySubtitle = null,
        emptyIcon = null,
        errorMessage = null,
        errorIcon = null,
        onRetry = null,
        retryLabel = 'Повторить',
        onEmptyAction = null,
        emptyActionLabel = 'Создать',
        variant = AppStateVariant.center,
        asSliver = false;

  /// Определяет состояние по флагам cubit / репозитория.
  static AppScreenState resolve({
    required bool isLoading,
    String? errorMessage,
    bool isEmpty = false,
  }) {
    if (isLoading) return AppScreenState.loading;
    if (errorMessage != null && errorMessage.trim().isNotEmpty) {
      return AppScreenState.error;
    }
    if (isEmpty) return AppScreenState.empty;
    return AppScreenState.content;
  }

  final AppScreenState state;
  final Widget child;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData? emptyIcon;
  final String? errorMessage;
  final IconData? errorIcon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onEmptyAction;
  final String emptyActionLabel;
  final AppStateVariant variant;
  final bool asSliver;

  bool get _isInline => variant == AppStateVariant.inline;

  @override
  Widget build(BuildContext context) {
    if (state == AppScreenState.content) return child;

    final body = _buildBody(context);
    if (!asSliver) return body;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (state) {
      AppScreenState.loading => _StateBody(
        visual: _AppStateVisual.loading(
          context: context,
          inline: _isInline,
        ),
        title: loadingMessage ?? 'Загрузка…',
        subtitle: null,
        variant: variant,
      ),
      AppScreenState.empty => _StateBody(
        visual: _AppStateVisual.empty(
          context: context,
          icon: emptyIcon ?? AppIcons.folderOpen.icon,
          inline: _isInline,
        ),
        title: emptyTitle ?? 'Ничего нет',
        subtitle: emptySubtitle,
        variant: variant,
        action: onEmptyAction == null
            ? null
            : AppButton(
                text: emptyActionLabel,
                onTap: onEmptyAction,
                isExpanded: _isInline,
              ),
      ),
      AppScreenState.error => _StateBody(
        visual: _AppStateVisual.error(
          context: context,
          icon: errorIcon ?? AppIcons.errorOutline.icon,
          inline: _isInline,
        ),
        title: errorMessage ?? 'Что-то пошло не так',
        subtitle: null,
        variant: variant,
        action: onRetry == null
            ? null
            : AppButton(
                text: retryLabel,
                onTap: onRetry,
                isExpanded: _isInline,
              ),
      ),
      AppScreenState.content => child,
    };
  }
}

class _AppStateVisual {
  const _AppStateVisual({
    required this.backgroundColor,
    required this.iconColor,
    required this.child,
    required this.size,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Widget child;
  final double size;

  factory _AppStateVisual.loading({
    required BuildContext context,
    required bool inline,
  }) {
    final colors = context.colors;
    final size = inline ? 44.0 : 72.0;
    final iconSize = inline ? 22.0 : 28.0;

    return _AppStateVisual(
      size: size,
      backgroundColor: colors.infoSoft,
      iconColor: colors.primary,
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: inline ? 2.2 : 2.8,
          color: colors.primary,
        ),
      ),
    );
  }

  factory _AppStateVisual.empty({
    required BuildContext context,
    required IconData icon,
    required bool inline,
  }) {
    final colors = context.colors;
    final size = inline ? 44.0 : 72.0;
    final iconSize = inline ? 22.0 : 32.0;

    return _AppStateVisual(
      size: size,
      backgroundColor: colors.surfaceMuted,
      iconColor: colors.iconMuted,
      child: Icon(icon, size: iconSize, color: colors.iconMuted),
    );
  }

  factory _AppStateVisual.error({
    required BuildContext context,
    required IconData icon,
    required bool inline,
  }) {
    final colors = context.colors;
    final size = inline ? 44.0 : 72.0;
    final iconSize = inline ? 22.0 : 32.0;

    return _AppStateVisual(
      size: size,
      backgroundColor: colors.functionalSoftRed,
      iconColor: colors.functionalSoftRedIcon,
      child: Icon(icon, size: iconSize, color: colors.functionalSoftRedIcon),
    );
  }

  Widget badge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.visual,
    required this.title,
    this.subtitle,
    required this.variant,
    this.action,
  });

  final _AppStateVisual visual;
  final String title;
  final String? subtitle;
  final AppStateVariant variant;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isInline = variant == AppStateVariant.inline;
    final titleStyle = isInline
        ? AppTextStyle.base(13, color: context.colors.subTextColor)
        : AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600);

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(isInline ? 16 : 32, isInline ? 12 : 32, isInline ? 16 : 32, isInline ? 8 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isInline ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: visual.badge(),
            ),
            SizedBox(height: isInline ? 10 : 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            if (subtitle != null) ...[
              SizedBox(height: isInline ? 4 : 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyle.base(isInline ? 12 : 14, color: context.colors.subTextColor),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: isInline ? 8 : 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
