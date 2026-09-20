import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_guide/data/services_guide_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsGuidePage extends StatefulWidget {
  const SettingsGuidePage({super.key});

  @override
  State<SettingsGuidePage> createState() => _SettingsGuidePageState();
}

class _SettingsGuidePageState extends State<SettingsGuidePage> {
  @override
  void initState() {
    super.initState();
    final cubit = sl<ProfileCubit>();
    if (cubit.state.mapOrNull(loaded: (_) => true) != true) {
      cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SettingsScreenShell(
      title: 'Гайд',
      body: BlocBuilder<ProfileCubit, ProfileState>(
        bloc: sl<ProfileCubit>(),
        builder: (context, profileState) {
          final profile = profileState.mapOrNull(loaded: (s) => s.profile);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              Text(
                'Коротко про сервисы Clover. Можно сразу активировать тег хозяина.',
                style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.4),
              ),
              const SizedBox(height: 16),
              for (final item in ServicesGuideCatalog.all) ...[
                _GuideHubCard(
                  content: item,
                  active: profile?.hasAccountTag(item.topic.adminTag) ?? false,
                  onTap: () => context.router.push(
                    SettingsGuideTopicRoute(topicKey: item.topic.key),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
            ],
          );
        },
      ),
    );
  }
}

class _GuideHubCard extends StatelessWidget {
  const _GuideHubCard({
    required this.content,
    required this.active,
    required this.onTap,
  });

  final ServicesGuideContent content;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = content.topic.serviceKind;
    final accent = service != null ? colors.serviceAccent(service) : null;
    final soft = accent?.soft ?? colors.surfaceSoft;
    final iconColor = accent?.icon ?? colors.primary;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSoft),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(content.cardIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.cardTitle,
                      style: AppTextStyle.base(
                        16,
                        color: colors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.cardSubtitle,
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? soft : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? 'Активно' : 'Активировать',
                  style: AppTextStyle.base(
                    11,
                    color: active
                        ? (accent?.onSoft ?? iconColor)
                        : colors.subTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
