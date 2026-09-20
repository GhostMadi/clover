import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class VenueInboxPage extends StatefulWidget {
  const VenueInboxPage({super.key, required this.venueId});

  final String venueId;

  @override
  State<VenueInboxPage> createState() => _VenueInboxPageState();
}

class _VenueInboxPageState extends State<VenueInboxPage> {
  VenueMockInboxTab _tab = VenueMockInboxTab.requests;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = venueServiceAccent(colors);
    final all = VenueMockCatalog.reservationsFor(widget.venueId);
    final items = all.where((e) => e.tab == _tab).toList();

    return VenueScreenShell(
      title: 'Inbox',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VenueMockBanner(
                  text: 'Запрос → soft-hold → admin решает. Не auto-confirm.',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tab in VenueMockInboxTab.values) ...[
                        _InboxChip(
                          label: VenueMockCatalog.tabLabel(tab),
                          selected: _tab == tab,
                          accent: accent,
                          onTap: () => setState(() => _tab = tab),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Пусто в этой вкладке',
                      style: AppTextStyle.base(14, color: colors.subTextColor),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      VenueScreenShell.scrollBottomGap(context),
                    ),
                    children: [
                      AppTileGroup(
                        children: [
                          for (final item in items)
                            AppTile(
                              title: item.guestName,
                              subtitle:
                                  '${item.placeLabel} · ${item.whenLabel} · ${VenueMockCatalog.statusLabel(item.status)}',
                              iconColor: accent.icon,
                              iconBackgroundColor: accent.soft,
                              showChevron: true,
                              onTap: () => context.router.push(
                                VenueInboxDetailRoute(
                                  venueId: widget.venueId,
                                  reservationId: item.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InboxChip extends StatelessWidget {
  const _InboxChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppServiceAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.cta : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent.ctaBorder : colors.borderSoft),
        ),
        child: Text(
          label,
          style: AppTextStyle.base(
            13,
            fontWeight: FontWeight.w600,
            color: selected ? accent.ctaForeground : colors.textColor,
          ),
        ),
      ),
    );
  }
}
