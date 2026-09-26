import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/booking_space_plan_bind_mock.dart';
import 'package:flutter/material.dart';

/// Mock: схема + ценники на emoji; одинаковые глифы — назначение пачкой.
class BookingSpacePlanBindMockPage extends StatefulWidget {
  const BookingSpacePlanBindMockPage({
    super.key,
    required this.pointId,
    this.pointName,
  });

  final String pointId;
  final String? pointName;

  @override
  State<BookingSpacePlanBindMockPage> createState() =>
      _BookingSpacePlanBindMockPageState();
}

class _BookingSpacePlanBindMockPageState extends State<BookingSpacePlanBindMockPage> {
  Future<void> _pickPlan() async {
    final plans = BookingSpacePlanBindMock.plans;
    final current = BookingSpacePlanBindMock.spacePlanId(widget.pointId);
    final options = [
      for (final p in plans)
        AppSingleSelectOption(
          value: p.id,
          label: '${p.title}${p.published ? '' : ' · draft'}',
        ),
    ];
    String? selected = current;
    await AppBottomSheet.show<void>(
      context: context,
      title: context.l10n.booking_space_plan_pick,
      service: kBookingService,
      contentHeight: MediaQuery.sizeOf(context).height * 0.48,
      content: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.booking_space_plan_emoji_only,
                style: AppTextStyle.base(13, color: ctx.colors.subTextColor),
              ),
              const SizedBox(height: 12),
              AppSingleSelect<String>(
                label: context.l10n.booking_space_plan_pick,
                hint: context.l10n.booking_space_plan_none,
                sheetTitle: context.l10n.booking_space_plan_pick,
                options: options,
                value: selected,
                service: kBookingService,
                onChanged: (id) => setLocal(() => selected = id),
              ),
              const Spacer(),
              AppButton(
                text: context.l10n.common_save,
                isExpanded: true,
                service: kBookingService,
                onTap: () {
                  BookingSpacePlanBindMock.setSpacePlan(widget.pointId, selected);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _edit({
    required String glyph,
    required List<BookingPlanEmojiSpot> spots,
    required bool allSame,
  }) async {
    final first = spots.first;
    final existing = BookingSpacePlanBindMock.bindFor(widget.pointId, first.nodeId);
    var serviceId = existing?.serviceId ?? BookingSpacePlanBindMock.mockServices.first.id;
    var staffId = existing?.staffId;
    var withStaff = staffId != null;

    await AppBottomSheet.show<void>(
      context: context,
      title: allSame ? '$glyph  ×${spots.length}' : '$glyph  ·  ${first.floor}',
      service: kBookingService,
      contentHeight: MediaQuery.sizeOf(context).height * 0.62,
      content: StatefulBuilder(
        builder: (ctx, setLocal) {
          final colors = ctx.colors;
          final staffOpts = BookingSpacePlanBindMock.mockStaff
              .where((s) => s.serviceIds.contains(serviceId))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                allSame
                    ? context.l10n.booking_space_plan_apply_all
                    : context.l10n.booking_space_plan_emoji_only,
                style: AppTextStyle.base(12, color: colors.subTextColor),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in spots)
                    Text(s.emoji, style: const TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 14),
              AppSingleSelect<String>(
                label: context.l10n.booking_services_label,
                hint: context.l10n.booking_space_plan_assign,
                sheetTitle: context.l10n.booking_services_label,
                options: [
                  for (final s in BookingSpacePlanBindMock.mockServices)
                    AppSingleSelectOption(
                      value: s.id,
                      label: '${s.title} · ${s.priceKzt} ₸',
                    ),
                ],
                value: serviceId,
                service: kBookingService,
                onChanged: (id) => setLocal(() {
                  serviceId = id;
                  staffId = null;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      label: context.l10n.booking_space_plan_service_only,
                      selected: !withStaff,
                      onTap: () => setLocal(() {
                        withStaff = false;
                        staffId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeChip(
                      label: context.l10n.booking_space_plan_service_staff,
                      selected: withStaff,
                      onTap: () => setLocal(() => withStaff = true),
                    ),
                  ),
                ],
              ),
              if (withStaff) ...[
                const SizedBox(height: 12),
                AppSingleSelect<String>(
                  label: context.l10n.booking_space_plan_staff,
                  hint: context.l10n.booking_space_plan_no_staff,
                  sheetTitle: context.l10n.booking_space_plan_staff,
                  options: [
                    for (final s in staffOpts)
                      AppSingleSelectOption(value: s.id, label: s.name),
                  ],
                  value: staffId,
                  service: kBookingService,
                  onChanged: (id) => setLocal(() => staffId = id),
                ),
              ],
              const Spacer(),
              AppButton(
                text: context.l10n.common_save,
                isExpanded: true,
                service: kBookingService,
                onTap: () {
                  if (withStaff && (staffId == null || staffId!.isEmpty)) return;
                  final svc = BookingSpacePlanBindMock.mockServices
                      .firstWhere((s) => s.id == serviceId);
                  final staff = !withStaff || staffId == null
                      ? null
                      : BookingSpacePlanBindMock.mockStaff
                          .where((s) => s.id == staffId)
                          .firstOrNull;
                  BookingSpacePlanBindMock.upsertBindsBulk(
                    pointId: widget.pointId,
                    nodeIds: spots.map((s) => s.nodeId).toList(),
                    emoji: glyph,
                    serviceId: svc.id,
                    serviceTitle: svc.title,
                    priceKzt: svc.priceKzt,
                    staffId: staff?.id,
                    staffName: staff?.name,
                  );
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                text: context.l10n.booking_space_plan_clear,
                isExpanded: true,
                service: kBookingService,
                onTap: () {
                  BookingSpacePlanBindMock.clearBinds(
                    widget.pointId,
                    spots.map((s) => s.nodeId).toList(),
                  );
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return BookingScreenShell(
      title: context.l10n.booking_space_plan_title,
      pointId: widget.pointId,
      compactBar: true,
      body: ValueListenableBuilder<int>(
        valueListenable: BookingSpacePlanBindMock.revision,
        builder: (context, _, __) {
          final planId = BookingSpacePlanBindMock.spacePlanId(widget.pointId);
          final planTitle = planId == null
              ? null
              : BookingSpacePlanBindMock.plans
                  .where((p) => p.id == planId)
                  .map((p) => p.title)
                  .firstOrNull;
          final groups = BookingSpacePlanBindMock.groupsForPoint(widget.pointId);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              BookingScreenShell.scrollBottomGap(context),
            ),
            children: [
              Text(
                context.l10n.booking_space_plan_mock_hint,
                style: AppTextStyle.base(12, color: colors.subTextColor),
              ),
              const SizedBox(height: 12),
              Material(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickPlan,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(AppIcons.locationOn.icon, color: accent.icon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                planTitle ?? context.l10n.booking_space_plan_none,
                                style: AppTextStyle.base(
                                  15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textColor,
                                ),
                              ),
                              Text(
                                context.l10n.booking_space_plan_pick,
                                style: AppTextStyle.base(12, color: colors.subTextColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(AppIcons.chevronRight.icon, color: colors.subTextColor),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.booking_space_plan_emoji_only,
                style: AppTextStyle.base(13, color: colors.subTextColor),
              ),
              const SizedBox(height: 10),
              if (planId == null)
                Text(
                  context.l10n.booking_space_plan_none,
                  style: AppTextStyle.base(14, color: colors.subTextColor),
                )
              else if (groups.isEmpty)
                Text(
                  context.l10n.booking_space_plan_no_emoji,
                  style: AppTextStyle.base(14, color: colors.subTextColor),
                )
              else
                ...groups.map((g) {
                  final binds = [
                    for (final s in g.spots)
                      BookingSpacePlanBindMock.bindFor(widget.pointId, s.nodeId),
                  ];
                  final assigned = binds.whereType<BookingEmojiBind>().toList();
                  final allSame = assigned.length == g.spots.length &&
                      assigned.every(
                        (b) =>
                            b.serviceId == assigned.first.serviceId &&
                            b.staffId == assigned.first.staffId,
                      );
                  final summary = allSame && assigned.isNotEmpty ? assigned.first : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(g.glyph, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Text(
                                '×${g.spots.length}',
                                style: AppTextStyle.base(
                                  14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textColor,
                                ),
                              ),
                              if (summary != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${summary.serviceTitle} · ${summary.priceKzt} ₸'
                                    '${summary.staffName != null ? ' · ${summary.staffName}' : ''}',
                                    style: AppTextStyle.base(
                                      12,
                                      fontWeight: FontWeight.w600,
                                      color: accent.icon,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                const Spacer(),
                              if (g.spots.length > 1)
                                GestureDetector(
                                  onTap: () => _edit(
                                    glyph: g.glyph,
                                    spots: g.spots,
                                    allSame: true,
                                  ),
                                  child: Text(
                                    context.l10n.booking_space_plan_all_same,
                                    style: AppTextStyle.base(
                                      13,
                                      fontWeight: FontWeight.w700,
                                      color: accent.icon,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in g.spots)
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _edit(
                                    glyph: s.emoji,
                                    spots: [s],
                                    allSame: false,
                                  ),
                                  child: Container(
                                    width: 64,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.borderSoft),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(s.emoji, style: const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 4),
                                        Text(
                                          () {
                                            final b = BookingSpacePlanBindMock.bindFor(
                                              widget.pointId,
                                              s.nodeId,
                                            );
                                            return b == null ? '—' : '${b.priceKzt}';
                                          }(),
                                          style: AppTextStyle.base(
                                            10,
                                            fontWeight: FontWeight.w700,
                                            color: accent.icon,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    return Material(
      color: selected ? accent.soft : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(
              12,
              fontWeight: FontWeight.w700,
              color: selected ? accent.icon : colors.subTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
