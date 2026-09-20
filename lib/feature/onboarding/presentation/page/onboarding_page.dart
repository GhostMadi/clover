import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/deep_link/app_deep_link_service.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_store.dart';
import 'package:clover/feature/onboarding/presentation/theme/onboarding_colors.dart';
import 'package:clover/feature/onboarding/presentation/widget/onboarding_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.replay = false,
  });

  /// Открыто из настроек — по «Начать» возвращаемся назад, а не на дашборд.
  final bool replay;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  OnboardingPath? _path;
  var _index = 0;
  var _finishing = false;

  List<OnboardingSlideData> get _slides =>
      _path == null ? const [] : OnboardingCatalog.slidesFor(_path!);

  bool get _isLast => _slides.isNotEmpty && _index >= _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : null;
    if (userId != null) {
      await sl<OnboardingStore>().markSeen(userId, OnboardingCatalog.appFlowId);
    }

    if (!mounted) return;
    if (widget.replay) {
      await context.router.maybePop();
      return;
    }
    await context.router.replaceAll([const AppDashboardRoute()]);
    if (mounted) {
      await sl<AppDeepLinkService>().flushPending();
    }
  }

  void _selectPath(OnboardingPath path) {
    setState(() {
      _path = path;
      _index = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    });
  }

  void _backToPathPicker() {
    setState(() {
      _path = null;
      _index = 0;
    });
  }

  void _next() {
    if (_path == null) return;
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  void _prev() {
    if (_path == null) return;
    if (_index == 0) {
      _backToPathPicker();
      return;
    }
    _controller.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finishing ? null : _finish,
                child: Text(
                  'Пропустить',
                  style: AppTextStyle.base(
                    15,
                    color: colors.subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _path == null
                  ? _PathPicker(
                      onSelect: _finishing ? null : _selectPath,
                    )
                  : PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final slide = _slides[i];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.widthByContext(28),
                          ),
                          child: Column(
                            children: [
                              const Spacer(flex: 2),
                              OnboardingIllustration(
                                kind: slide.illustration,
                                active: i == _index,
                              ),
                              SizedBox(height: context.heightByContext(28)),
                              Text(
                                slide.emoji,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context
                                      .heightByContext(36)
                                      .clamp(28.0, 40.0),
                                ),
                              ),
                              SizedBox(height: context.heightByContext(10)),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.base(
                                  context.heightByContext(28).clamp(22.0, 30.0),
                                  color: colors.textColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: context.heightByContext(12)),
                              Text(
                                slide.body,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.base(
                                  context.heightByContext(16).clamp(14.0, 17.0),
                                  color: colors.subTextColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                              if (slide.tip != null) ...[
                                SizedBox(height: context.heightByContext(14)),
                                Text(
                                  slide.tip!,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.base(
                                    context
                                        .heightByContext(14)
                                        .clamp(12.0, 15.0),
                                    color: colors.iconMuted,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const Spacer(flex: 3),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_path != null) ...[
              _Dots(
                count: _slides.length,
                index: _index,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.widthByContext(24),
                  context.heightByContext(20),
                  context.widthByContext(24),
                  context.heightByContext(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppOutlinedButton(
                        text: 'Назад',
                        onTap: _finishing ? null : _prev,
                      ),
                    ),
                    SizedBox(width: context.widthByContext(12)),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: _isLast ? 'Начать' : 'Далее',
                        isLoading: _finishing,
                        onTap: _finishing ? null : _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PathPicker extends StatelessWidget {
  const _PathPicker({required this.onSelect});

  final ValueChanged<OnboardingPath>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.widthByContext(28)),
      children: [
        SizedBox(height: context.heightByContext(12)),
        const Center(
          child: OnboardingIllustration(
            kind: OnboardingIllustrationKind.welcome,
            active: true,
          ),
        ),
        SizedBox(height: context.heightByContext(24)),
        Text(
          '🍀',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.heightByContext(36).clamp(28.0, 40.0),
          ),
        ),
        SizedBox(height: context.heightByContext(10)),
        Text(
          'Кто ты в Clover?',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(
            context.heightByContext(26).clamp(22.0, 28.0),
            color: colors.textColor,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: context.heightByContext(10)),
        Text(
          'Короткий тур под тебя',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(
            context.heightByContext(15).clamp(13.0, 16.0),
            color: colors.subTextColor,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        SizedBox(height: context.heightByContext(28)),
        AppButton(
          text: 'Лента',
          onTap: onSelect == null ? null : () => onSelect!(OnboardingPath.feed),
        ),
        SizedBox(height: context.heightByContext(10)),
        _SoftAccentButton(
          text: 'Бизнес и предприятия',
          onTap: onSelect == null
              ? null
              : () => onSelect!(OnboardingPath.business),
        ),
        SizedBox(height: context.heightByContext(10)),
        AppOutlinedButton(
          text: 'И лента, и дело',
          onTap: onSelect == null ? null : () => onSelect!(OnboardingPath.both),
        ),
        SizedBox(height: context.heightByContext(24)),
      ],
    );
  }
}

class _SoftAccentButton extends StatefulWidget {
  const _SoftAccentButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  State<_SoftAccentButton> createState() => _SoftAccentButtonState();
}

class _SoftAccentButtonState extends State<_SoftAccentButton>
    with SingleTickerProviderStateMixin {
  late final JellyPressController _jelly;

  @override
  void initState() {
    super.initState();
    _jelly = JellyPressController(
      vsync: this,
      onAnimationSwap: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _jelly.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    _jelly.trigger();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onTap != null;

    return AnimatedBuilder(
      animation: _jelly.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jelly.scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? colors.functionalSoftRed : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? colors.functionalSoftRedIcon.withValues(alpha: 0.35)
                  : colors.border,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.shadowDark.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: AppTextStyle.base(
              16,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? colors.functionalSoftRedIcon
                  : colors.subTextColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  static const _dotColors = OnboardingColors.accents;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? _dotColors[i % _dotColors.length]
                  : colors.borderSoft,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}
