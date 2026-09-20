import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_error.dart';
import 'package:clover/feature/_profile_/edit_profile/data/repository/edit_profile_repository.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_guide/data/services_guide_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsGuideTopicPage extends StatefulWidget {
  const SettingsGuideTopicPage({super.key, required this.topicKey});

  final String topicKey;

  @override
  State<SettingsGuideTopicPage> createState() => _SettingsGuideTopicPageState();
}

class _SettingsGuideTopicPageState extends State<SettingsGuideTopicPage> {
  var _activating = false;

  @override
  void initState() {
    super.initState();
    final cubit = sl<ProfileCubit>();
    final loaded = cubit.state.mapOrNull(loaded: (_) => true) ?? false;
    if (!loaded) {
      cubit.load();
    }
  }

  Future<void> _activate(ServicesGuideContent content) async {
    if (_activating) return;
    setState(() => _activating = true);
    try {
      final profile = await sl<EditProfileRepository>().addAccountTag(
        content.topic.adminTag,
      );
      sl<ProfileCubit>().applyProfile(profile);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Сервис включён на профиле',
        kind: AppSnackBarKind.success,
      );
    } on EditProfileError catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.message,
        kind: AppSnackBarKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Не удалось активировать',
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  void _openHub(ServicesGuideTopic topic) {
    switch (topic) {
      case ServicesGuideTopic.booking:
        context.router.push(const SettingsBookingRoute());
      case ServicesGuideTopic.attendance:
        context.router.push(const SettingsAttendanceRoute());
      case ServicesGuideTopic.resources:
        context.router.push(const SettingsResourcesRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ServicesGuideCatalog.tryByKey(widget.topicKey);
    if (content == null) {
      return SettingsScreenShell(
        title: 'Гайд',
        body: Center(
          child: Text(
            'Тема гайда не найдена',
            style: AppTextStyle.base(15, color: context.colors.subTextColor),
          ),
        ),
      );
    }

    final colors = context.colors;
    final service = content.topic.serviceKind;
    final accent = service != null ? colors.serviceAccent(service) : null;

    return SettingsScreenShell(
      title: content.pageTitle,
      service: service,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        bloc: sl<ProfileCubit>(),
        builder: (context, profileState) {
          final profile = profileState.mapOrNull(loaded: (s) => s.profile);
          final hasTag =
              profile?.hasAccountTag(content.topic.adminTag) ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
                    _GuideHero(
                      icon: content.cardIcon,
                      lead: content.lead,
                      accentSoft: accent?.soft ?? colors.surfaceSoft,
                      accentIcon: accent?.icon ?? colors.primary,
                      onSoft: accent?.onSoft ?? colors.textColor,
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < content.steps.length; i++) ...[
                      _GuideStepCard(
                        index: i + 1,
                        title: content.steps[i].title,
                        body: content.steps[i].body,
                        accentSoft: accent?.soft ?? colors.surfaceSoft,
                        accentIcon: accent?.icon ?? colors.primary,
                        onSoft: accent?.onSoft ?? colors.textColor,
                      ),
                if (i < content.steps.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 20),
              if (hasTag)
                AppButton(
                  text: content.topic.openLabel,
                  service: service,
                  isExpanded: true,
                  onTap: () => _openHub(content.topic),
                )
              else
                AppButton(
                  text: content.topic.activateLabel,
                  service: service,
                  isExpanded: true,
                  isLoading: _activating,
                  onTap: _activating ? null : () => _activate(content),
                ),
              SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
            ],
          );
        },
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero({
    required this.icon,
    required this.lead,
    required this.accentSoft,
    required this.accentIcon,
    required this.onSoft,
  });

  final IconData icon;
  final String lead;
  final Color accentSoft;
  final Color accentIcon;
  final Color onSoft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentIcon, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              lead,
              style: AppTextStyle.base(
                15,
                color: onSoft,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.index,
    required this.title,
    required this.body,
    required this.accentSoft,
    required this.accentIcon,
    required this.onSoft,
  });

  final int index;
  final String title;
  final String body;
  final Color accentSoft;
  final Color accentIcon;
  final Color onSoft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: AppTextStyle.base(
                14,
                color: onSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.base(
                    16,
                    color: colors.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppTextStyle.base(
                    14,
                    color: colors.subTextColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
