import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/cubit/booking_client_cubit.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_bonus_switch.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_comment_field.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_executor_picker.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_service_picker.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_step_header.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_summary.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_time_slots.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/booking_space_plan_bind_mock.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/cafe_space_plan_asset.dart';
import 'package:clover/feature/_booking_/space_plan_bind/presentation/page/booking_space_plan_guest_mock_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingClientPage extends StatefulWidget {
  const BookingClientPage({
    super.key,
    required this.hostId,
    required this.hostDisplayName,
    this.initialServiceId,
  });

  final String hostId;
  final String hostDisplayName;
  final String? initialServiceId;

  @override
  State<BookingClientPage> createState() => _BookingClientPageState();
}

class _BookingClientPageState extends State<BookingClientPage> {
  late final BookingClientCubit _cubit;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateKey = GlobalKey();

  List<BookingEmojiBind> _selectedSpots = const [];
  var _catalogSeeded = false;
  /// Путь: схема → услуга, или просто услуга.
  var _viaPlan = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingClientCubit>()
      ..init(
        hostId: widget.hostId,
        hostDisplayName: widget.hostDisplayName,
        initialServiceId: widget.initialServiceId,
      );
    _commentController.addListener(() => setState(() {}));
    if (BookingSpacePlanBindMock.enabled) {
      BookingSpacePlanBindMock.ensureGuestShowcase(widget.hostId);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<BookingServiceWithStaff> get _catalog {
    return _cubit.state.maybeMap(ready: (s) => s.catalog, orElse: () => const []);
  }

  List<BookingServiceExecutor> _staffFor(String? serviceId) {
    if (serviceId == null) return const [];
    return _catalog.where((c) => c.service.id == serviceId).firstOrNull?.staff ?? const [];
  }

  Future<void> _seedBindsFromCatalog(List<BookingServiceWithStaff> catalog) async {
    if (_catalogSeeded || !BookingSpacePlanBindMock.enabled) return;
    _catalogSeeded = true;
    try {
      final floors = await CafeSpacePlanAsset.load(forceReload: true);
      final active = catalog.where((c) => c.service.isActive).toList();
      BookingSpacePlanBindMock.seedGuestBindsFromCatalog(
        hostId: widget.hostId,
        spots: [
          for (final f in floors)
            for (final n in f.bookableEmojiNodes) (nodeId: n.id, emoji: n.label ?? '💺'),
        ],
        services: [
          for (final c in active)
            (
              id: c.service.id,
              title: c.service.title,
              priceKzt: c.service.price.round(),
              emoji: c.service.emojiText,
              staff: [
                for (final s in c.staff) (id: s.id, name: s.displayName),
              ],
            ),
        ],
      );
    } catch (_) {
      _catalogSeeded = false;
    }
  }

  Future<void> _openPlan() async {
    await _seedBindsFromCatalog(_catalog);
    if (!mounted) return;
    final result = await Navigator.of(context).push<List<BookingEmojiBind>>(
      MaterialPageRoute(
        builder: (_) => BookingSpacePlanGuestMockPage(
          hostId: widget.hostId,
          hostDisplayName: widget.hostDisplayName,
        ),
      ),
    );
    if (!mounted || result == null || result.isEmpty) return;
    _applyPlaceSelection(result);
  }

  void _applyPlaceSelection(List<BookingEmojiBind> spots) {
    final primary = spots.first;
    setState(() {
      _selectedSpots = spots;
      _viaPlan = true;
    });

    final matched = _resolveService(primary);
    if (matched == null) {
      AppSnackBar.show(
        context,
        message: context.l10n.booking_space_plan_open_visual_sub,
        kind: AppSnackBarKind.info,
      );
      return;
    }

    final staff = matched.staff;
    BookingServiceExecutor? executor;
    if (primary.staffId != null && primary.staffId!.isNotEmpty) {
      executor = staff.where((s) => s.id == primary.staffId).firstOrNull;
    }
    if (executor == null && primary.staffName != null && primary.staffName!.isNotEmpty) {
      final name = primary.staffName!.toLowerCase();
      executor = staff.where((s) => s.displayName.toLowerCase() == name).firstOrNull;
    }
    executor ??= staff.isNotEmpty ? staff.first : null;
    if (executor == null) return;

    _cubit.applyPlaceSelection(service: matched.service, executor: executor);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dateKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  BookingServiceWithStaff? _resolveService(BookingEmojiBind bind) {
    final byId = _catalog.where((c) => c.service.id == bind.serviceId).firstOrNull;
    if (byId != null && byId.service.isActive) return byId;

    final byTitle = _catalog
        .where((c) => c.service.isActive && c.service.title == bind.serviceTitle)
        .firstOrNull;
    if (byTitle != null) return byTitle;

    final byEmoji = _catalog
        .where((c) => c.service.isActive && c.service.emojiText == bind.emoji)
        .firstOrNull;
    if (byEmoji != null) return byEmoji;

    return _catalog.where((c) => c.service.isActive).firstOrNull;
  }

  void _clearPlace() {
    setState(() {
      _selectedSpots = const [];
      _viaPlan = false;
    });
  }

  Future<void> _confirm(BookingClientState state) async {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    var comment = _commentController.text.trim();
    if (_selectedSpots.isNotEmpty) {
      final place = _selectedSpots.map((b) => '${b.emoji} ${b.serviceTitle}').join(', ');
      comment = comment.isEmpty ? place : '$comment · $place';
    }

    final ok = await _cubit.confirm(clientComment: comment.isEmpty ? null : comment);
    if (!mounted) return;

    if (ok) {
      AppSnackBar.show(context, message: context.l10n.booking_confirmed_toast, kind: AppSnackBarKind.success);
      context.router.maybePop(true);
      return;
    }

    final message = _cubit.state.maybeMap(ready: (s) => s.conflictMessage, orElse: () => null);
    if (message != null) {
      AppSnackBar.show(
        context,
        message: message.contains('BookingException') ? BookingException.from(message).userMessage : message,
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final showPlan = BookingSpacePlanBindMock.enabled;

    return BlocConsumer<BookingClientCubit, BookingClientState>(
      bloc: _cubit,
      listenWhen: (prev, next) {
        final wasReady = prev.mapOrNull(ready: (_) => true) == true;
        final isReady = next.mapOrNull(ready: (_) => true) == true;
        return !wasReady && isReady;
      },
      listener: (context, state) {
        final ready = state.mapOrNull(ready: (s) => s);
        if (ready != null) {
          _seedBindsFromCatalog(ready.catalog);
        }
      },
      builder: (context, state) {
        final ready = state.mapOrNull(ready: (s) => s);
        final service = ready?.selectedService;
        final executor = ready?.selectedExecutor;
        final canConfirm = ready != null &&
            service != null &&
            executor != null &&
            ready.selectedSlotStart != null &&
            !ready.isSubmitting;

        return BookingScreenShell(
          title: '${context.l10n.booking_book_with} ${widget.hostDisplayName}',
          compactBar: true,
          isLoading: state.maybeMap(loading: (_) => true, orElse: () => ready?.isSubmitting ?? false),
          showSave: false,
          body: state.maybeMap(
            loading: (_) => const BookingLoader(),
            error: (s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(14, color: colors.subTextColor),
                ),
              ),
            ),
            orElse: () {
              if (ready == null) return const SizedBox.shrink();

              final services = [for (final entry in ready.catalog) entry.service];
              final executors = _staffFor(service?.id);

              String? dayUnavailableMessage;
              final reason = ready.dayUnavailableReason;
              if (reason != null && reason.isNotEmpty) {
                dayUnavailableMessage = switch (reason) {
                  'rest_day' => context.l10n.booking_day_unavailable_rest,
                  'executor_absent' => context.l10n.booking_day_unavailable_executor(
                    executor?.displayName ?? context.l10n.booking_master,
                  ),
                  _ => context.l10n.booking_day_unavailable,
                };
              }

              final placeDone = _selectedSpots.isNotEmpty;
              final serviceDone = service != null;
              final masterDone = executor != null;
              final stepService = showPlan ? 2 : 1;
              final stepMaster = showPlan ? 3 : 2;
              final stepDate = showPlan ? 4 : 3;

              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showPlan) ...[
                      ClientBookingStepHeader(
                        step: 1,
                        title: context.l10n.booking_space_plan_path_visual,
                        subtitle: context.l10n.booking_space_plan_open_visual_sub,
                      ),
                      const SizedBox(height: 10),
                      _GuestPlanTile(
                        selected: _selectedSpots,
                        onOpen: _openPlan,
                        onClear: _clearPlace,
                      ),
                      if (placeDone && serviceDone) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: accent.soft.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            masterDone
                                ? context.l10n.booking_space_plan_next_date
                                : '${_selectedSpots.first.emoji} ${_selectedSpots.first.serviceTitle}'
                                    '${_selectedSpots.first.staffName != null ? ' · ${_selectedSpots.first.staffName}' : ''}',
                            style: AppTextStyle.base(
                              13,
                              fontWeight: FontWeight.w700,
                              color: accent.onSoft,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.booking_space_plan_path_service,
                        style: AppTextStyle.base(12, fontWeight: FontWeight.w700, color: colors.subTextColor),
                      ),
                      const SizedBox(height: 8),
                    ],

                    ClientBookingServicePicker(
                      services: services,
                      selectedId: service?.id,
                      onSelected: (s) {
                        if (_viaPlan) setState(() => _viaPlan = false);
                        _cubit.selectService(s);
                      },
                      step: stepService,
                    ),
                    if (service != null) ...[
                      const SizedBox(height: 22),
                      ClientBookingExecutorPicker(
                        executors: executors,
                        selectedId: executor?.id,
                        onSelected: _cubit.selectExecutor,
                        step: stepMaster,
                      ),
                    ],
                    const SizedBox(height: 22),
                    KeyedSubtree(
                      key: _dateKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClientBookingStepHeader(
                            step: stepDate,
                            title: context.l10n.common_date,
                            subtitle: context.l10n.booking_pick_visit_day,
                          ),
                          const SizedBox(height: 12),
                          AppDatePicker(
                            hint: context.l10n.booking_pick_day,
                            value: ready.selectedDay,
                            firstDate: _today,
                            lastDate: ready.schedule.lastBookableDay,
                            onChanged: _cubit.selectDay,
                            service: kBookingService,
                          ),
                        ],
                      ),
                    ),
                    if (service != null && executor != null) ...[
                      if (dayUnavailableMessage != null) ...[
                        const SizedBox(height: 12),
                        ClientBookingConflictBanner(message: dayUnavailableMessage),
                      ] else if (ready.isLoadingSlots) ...[
                        const SizedBox(height: 20),
                        const BookingLoader(),
                      ] else ...[
                        const SizedBox(height: 22),
                        ClientBookingTimeSlots(slots: ready.slots, onSlotTap: _cubit.selectSlot),
                      ],
                    ],
                    if (ready.conflictMessage != null) ...[
                      const SizedBox(height: 12),
                      ClientBookingConflictBanner(message: ready.conflictMessage!),
                    ],
                    if (service != null && executor != null) ...[
                      const SizedBox(height: 22),
                      ClientBookingCommentField(controller: _commentController),
                      if (service.bonusPayPercent > 0) ...[
                        const SizedBox(height: 16),
                        ClientBookingBonusSwitch(
                          service: service,
                          balance: ready.bonusBalanceAtHost,
                          value: ready.useBonuses,
                          onChanged: _cubit.setUseBonuses,
                        ),
                      ],
                    ],
                    if (service != null && executor != null && ready.selectedSlotStart != null) ...[
                      const SizedBox(height: 18),
                      ClientBookingSummary(
                        hostDisplayName: widget.hostDisplayName,
                        executor: executor,
                        service: service,
                        startsAt: ready.selectedSlotStart!,
                        clientComment: _commentController.text,
                        useBonuses: ready.useBonuses,
                        bonusBalance: ready.bonusBalanceAtHost,
                        placeLine: _selectedSpots.isEmpty
                            ? null
                            : _selectedSpots.map((b) {
                                final master = b.staffName != null ? ' · ${b.staffName}' : '';
                                return '${b.emoji} ${b.serviceTitle}$master · ${b.priceKzt} ₸';
                              }).join(' · '),
                      ),
                      const SizedBox(height: 16),
                      BookingPrimaryButton(
                        text: context.l10n.booking_book_action,
                        isExpanded: true,
                        isLoading: ready.isSubmitting,
                        onTap: canConfirm ? () => _confirm(state) : null,
                      ),
                    ] else if (service != null && executor != null) ...[
                      const SizedBox(height: 20),
                      BookingPrimaryButton(
                        text: context.l10n.booking_book_action,
                        isExpanded: true,
                        interactive: false,
                        onTap: null,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GuestPlanTile extends StatelessWidget {
  const _GuestPlanTile({
    required this.selected,
    required this.onOpen,
    required this.onClear,
  });

  final List<BookingEmojiBind> selected;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final hasSelection = selected.isNotEmpty;
    final subtitle = hasSelection
        ? selected.map((b) => '${b.emoji} ${b.serviceTitle} · ${b.priceKzt} ₸').join(' · ')
        : context.l10n.booking_space_plan_open_visual_sub;

    return Material(
      color: accent.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(AppIcons.gridView.icon, color: accent.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.booking_space_plan_open_visual,
                      style: AppTextStyle.base(
                        15,
                        fontWeight: FontWeight.w700,
                        color: accent.onSoft,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        12,
                        color: accent.onSoft.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSelection)
                GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(AppIcons.close.icon, size: 18, color: accent.onSoft.withValues(alpha: 0.65)),
                  ),
                ),
              Icon(AppIcons.chevronRight.icon, color: accent.onSoft.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
