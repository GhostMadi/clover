import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_resources/data/resources_guide_catalog.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsResourcesGuidePage extends StatelessWidget {
  const SettingsResourcesGuidePage({super.key, required this.topicKey});

  final String topicKey;

  @override
  Widget build(BuildContext context) {
    final content = ResourcesGuideCatalog.tryByKey(topicKey);
    if (content == null) {
      return SettingsScreenShell(
        title: 'Гайд',
        service: kResourcesService,
        body: Center(
          child: Text(
            'Тема гайда не найдена',
            style: AppTextStyle.base(15, color: context.colors.subTextColor),
          ),
        ),
      );
    }

    final accent = context.colors.serviceAccent(kResourcesService);
    final colors = context.colors;

    return SettingsScreenShell(
      title: content.pageTitle,
      service: kResourcesService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.lead,
                style: AppTextStyle.base(15, color: colors.textColor, height: 1.45),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < content.steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _GuideStepCard(
                index: i + 1,
                title: content.steps[i].title,
                body: content.steps[i].body,
                accent: accent,
              ),
            ],
            if (content.ctaLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: content.ctaLabel!,
                service: kResourcesService,
                isExpanded: true,
                onTap: () => _openCta(context, content.topic),
              ),
            ],
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }

  void _openCta(BuildContext context, ResourcesGuideTopic topic) {
    switch (topic) {
      case ResourcesGuideTopic.locations:
        context.router.push(const LocationRoute());
      case ResourcesGuideTopic.filters:
        context.router.push(const SettingsFiltersRoute());
      case ResourcesGuideTopic.overview:
        break;
    }
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.index,
    required this.title,
    required this.body,
    required this.accent,
  });

  final int index;
  final String title;
  final String body;
  final AppServiceAccent accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: AppTextStyle.base(
                13,
                color: accent.icon,
                fontWeight: FontWeight.w700,
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
                    15,
                    color: colors.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
