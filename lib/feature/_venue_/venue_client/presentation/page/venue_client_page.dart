import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:clover/feature/_venue_/shared/data/venue_published_plan_loader.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_mock_widgets.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_screen_shell.dart';
import 'package:clover/feature/_venue_/shared/presentation/widget/venue_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class VenueClientPage extends StatefulWidget {
  const VenueClientPage({super.key, required this.venueId});

  final String venueId;

  @override
  State<VenueClientPage> createState() => _VenueClientPageState();
}

class _VenueClientPageState extends State<VenueClientPage> {
  final Set<String> _selected = {};
  int _guests = 2;
  VenuePublishedPlan? _published;
  var _loadingPlan = false;

  @override
  void initState() {
    super.initState();
    if (widget.venueId == 'cafe') {
      _loadingPlan = true;
      VenuePublishedPlanLoader.loadCafe().then((plan) {
        if (!mounted) return;
        setState(() {
          _loadingPlan = false;
          _published = plan;
        });
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _loadingPlan = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = VenueMockCatalog.venueById(widget.venueId);
    final fallbackNodes = VenueMockCatalog.planFor(widget.venueId);
    final tickets = VenueMockCatalog.ticketsFor(widget.venueId);
    final seats = VenueMockCatalog.seatsFor(widget.venueId);
    final sessions = VenueMockCatalog.sessionsFor(widget.venueId);
    final colors = context.colors;
    final nodes = _published?.nodes ?? fallbackNodes;
    final hasPlan = nodes.isNotEmpty;

    return VenueScreenShell(
      title: venue?.name ?? context.l10n.venue_hub_title,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, VenueScreenShell.scrollBottomGap(context)),
        children: [
          VenueMockBanner(
            text: widget.venueId == 'cafe'
                ? context.l10n.venue_client_schema_hint
                : context.l10n.venue_client_flow,
          ),
          const SizedBox(height: 12),
          if (sessions.isNotEmpty) ...[
            Text(
              context.l10n.venue_session,
              style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.subTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${sessions.first.title} · ${sessions.first.whenLabel}',
              style: AppTextStyle.base(16, fontWeight: FontWeight.w700, color: colors.textColor),
            ),
            const SizedBox(height: 16),
          ],
          if (_loadingPlan)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: colors.functionalSoftVenueIcon),
              ),
            )
          else if (hasPlan) ...[
            const VenueStateLegend(),
            const SizedBox(height: 12),
            VenuePlanCanvas(
              nodes: nodes,
              aspectRatio: _published?.aspectRatio ?? 1.05,
              selectedIds: _selected,
              onTapNode: (node) {
                if (node.state != VenueMockBookableState.free) {
                  AppSnackBar.show(context, message: VenueMockCatalog.stateLabel(node.state));
                  return;
                }
                setState(() {
                  if (_selected.contains(node.id)) {
                    _selected.remove(node.id);
                  } else {
                    _selected
                      ..clear()
                      ..add(node.id);
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ] else if (seats.isNotEmpty) ...[
            const VenueStateLegend(),
            const SizedBox(height: 12),
            for (final seat in seats)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SelectableRow(
                  title: seat.label,
                  subtitle: VenueMockCatalog.stateLabel(seat.state),
                  selected: _selected.contains(seat.id),
                  enabled: seat.state == VenueMockBookableState.free,
                  soft: venueStateSoft(colors, seat.state),
                  ink: venueStateInk(colors, seat.state),
                  onTap: () {
                    setState(() {
                      if (_selected.contains(seat.id)) {
                        _selected.remove(seat.id);
                      } else {
                        _selected
                          ..clear()
                          ..add(seat.id);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 12),
          ] else ...[
            for (final ticket in tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SelectableRow(
                  title: ticket.title,
                  subtitle: context.l10n.venue_ticket_remaining(ticket.priceHint, ticket.remaining),
                  selected: _selected.contains(ticket.id),
                  enabled: true,
                  soft: venueServiceAccent(colors).soft,
                  ink: venueServiceAccent(colors).icon,
                  onTap: () {
                    setState(() {
                      _selected
                        ..clear()
                        ..add(ticket.id);
                    });
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
          Text(
            context.l10n.venue_guests,
            style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.subTextColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _GuestBtn(
                label: '−',
                onTap: () => setState(() => _guests = (_guests - 1).clamp(1, 12)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_guests',
                  style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: colors.textColor),
                ),
              ),
              _GuestBtn(
                label: '+',
                onTap: () => setState(() => _guests = (_guests + 1).clamp(1, 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          VenuePrimaryButton(
            text: _selected.isEmpty ? context.l10n.venue_pick_place : context.l10n.venue_send_request,
            onTap: _selected.isEmpty
                ? null
                : () => AppSnackBar.show(
                      context,
                      message: context.l10n.venue_mock_request_sent,
                    ),
          ),
        ],
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.soft,
    required this.ink,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final Color soft;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = venueServiceAccent(colors);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent.cta : colors.borderSoft,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.base(15, fontWeight: FontWeight.w700, color: ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyle.base(12, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestBtn extends StatelessWidget {
  const _GuestBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = venueServiceAccent(context.colors);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: accent.onSoft),
        ),
      ),
    );
  }
}
