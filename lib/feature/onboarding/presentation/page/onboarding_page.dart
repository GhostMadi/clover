import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_store.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
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
  final _slides = OnboardingCatalog.appV1Slides;
  var _index = 0;
  var _finishing = false;

  bool get _isLast => _index >= _slides.length - 1;

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
      await sl<OnboardingStore>().markSeen(userId, OnboardingTipId.appV1);
    }

    if (!mounted) return;
    if (widget.replay) {
      await context.router.maybePop();
      return;
    }
    await context.router.replaceAll([const AppDashboardRoute()]);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
              child: PageView.builder(
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
                            fontSize: context.heightByContext(36).clamp(28.0, 40.0),
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
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
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
              child: AppButton(
                text: _isLast ? 'Начать' : 'Далее',
                isLoading: _finishing,
                onTap: _finishing ? null : _next,
              ),
            ),
          ],
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
    final colors = AppColors.of(context);
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
              color: i == index ? _dotColors[i % _dotColors.length] : colors.borderSoft,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}
