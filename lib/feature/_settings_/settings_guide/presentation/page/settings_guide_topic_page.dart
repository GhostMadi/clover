import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_guide/data/services_guide_catalog.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsGuideTopicPage extends StatelessWidget {
  const SettingsGuideTopicPage({super.key, required this.topicKey});

  final String topicKey;

  @override
  Widget build(BuildContext context) {
    final content = ServicesGuideCatalog.tryByKey(topicKey);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent?.soft ?? colors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.lead,
                style: AppTextStyle.base(15, color: colors.textColor, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            for (final step in content.steps) ...[
              Text(
                step.title,
                style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                step.body,
                style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
            if (content.topic == ServicesGuideTopic.resources) ...[
              AppButton(
                text: 'Открыть ресурсы',
                service: kResourcesService,
                isExpanded: true,
                onTap: () => context.router.push(const SettingsResourcesRoute()),
              ),
              const SizedBox(height: 10),
            ],
            if (content.topic == ServicesGuideTopic.booking) ...[
              AppButton(
                text: 'Открыть запись',
                service: AppServiceKind.booking,
                isExpanded: true,
                onTap: () => context.router.push(const SettingsBookingRoute()),
              ),
              const SizedBox(height: 10),
            ],
            if (content.topic == ServicesGuideTopic.attendance) ...[
              AppButton(
                text: 'Открыть посещаемость',
                service: AppServiceKind.attendance,
                isExpanded: true,
                onTap: () => context.router.push(const SettingsAttendanceRoute()),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
          ],
        ),
      ),
    );
  }
}
