import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/data/venue_published_plan_loader.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class VenuePlanPage extends StatefulWidget {
  const VenuePlanPage({super.key, required this.venueId});

  final String venueId;

  @override
  State<VenuePlanPage> createState() => _VenuePlanPageState();
}

class _VenuePlanPageState extends State<VenuePlanPage> {
  VenuePublishedPlan? _published;
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.venueId == 'cafe') {
      _loading = true;
      VenuePublishedPlanLoader.loadCafe().then((plan) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _published = plan;
          if (plan == null) _error = 'Не удалось загрузить план';
        });
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Ошибка загрузки плана';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = VenueMockCatalog.venueById(widget.venueId);
    final fallbackNodes = VenueMockCatalog.planFor(widget.venueId);
    final colors = context.colors;
    final usePublished = widget.venueId == 'cafe';

    return VenueScreenShell(
      title: 'План / схема',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          VenueMockBanner(
            text: usePublished
                ? 'Сайт нарисовал → мобилка только смотрит (JSON с сайта, мок).'
                : (venue?.hasPlan == true
                    ? 'Превью схемы. Рисовать и править — только на сайте.'
                    : 'Схемы нет. Хозяин может остаться на билетах / списке.'),
          ),
          const SizedBox(height: 12),
          const VenueStateLegend(),
          const SizedBox(height: 16),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: colors.functionalSoftVenueIcon),
              ),
            )
          else if (_error != null)
            Text(_error!, style: AppTextStyle.base(14, color: colors.error))
          else if (_published != null) ...[
            Text(
              '${_published!.floorLabel} · v${_published!.version} · published',
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
            const SizedBox(height: 10),
            VenuePlanCanvas(
              nodes: _published!.nodes,
              aspectRatio: _published!.aspectRatio,
            ),
          ] else if (fallbackNodes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderSoft),
              ),
              child: Text(
                'Пустой холст. На сайте появится редактор «как Figma».',
                style: AppTextStyle.base(14, color: colors.subTextColor),
              ),
            )
          else
            VenuePlanCanvas(nodes: fallbackNodes),
        ],
      ),
    );
  }
}
