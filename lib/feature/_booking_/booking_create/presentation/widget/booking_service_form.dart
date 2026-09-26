import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clover/core/extension/context.dart';

/// Форма услуги: сверху суть (название, emoji, время, цена, мастера), остальное — в «Ещё».
class BookingServiceForm extends StatefulWidget {
  const BookingServiceForm({
    super.key,
    required this.draft,
    required this.titleController,
    required this.durationController,
    required this.emojiController,
    required this.priceController,
    required this.maxParticipantsController,
    required this.bufferAfterController,
    required this.bonusPayPercentController,
    required this.bonusEarnAmountController,
    required this.descriptionController,
    required this.onDraftChanged,
    this.selectedExecutors = const [],
    this.onRemoveExecutor,
    this.onAddExecutor,
    this.onActiveChanged,
    this.enabled = true,
    this.bufferAfterLocked = false,
  });

  final BookingServiceDraft draft;
  final TextEditingController titleController;
  final TextEditingController durationController;
  final TextEditingController emojiController;
  final TextEditingController priceController;
  final TextEditingController maxParticipantsController;
  final TextEditingController bufferAfterController;
  final TextEditingController bonusPayPercentController;
  final TextEditingController bonusEarnAmountController;
  final TextEditingController descriptionController;
  final VoidCallback onDraftChanged;
  final List<BookingServiceExecutor> selectedExecutors;
  final ValueChanged<String>? onRemoveExecutor;
  final VoidCallback? onAddExecutor;
  final ValueChanged<bool>? onActiveChanged;
  final bool enabled;
  final bool bufferAfterLocked;

  @override
  State<BookingServiceForm> createState() => _BookingServiceFormState();
}

class _BookingServiceFormState extends State<BookingServiceForm> {
  static final _intFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _priceFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  late bool _moreOpen;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _moreOpen = d.maxParticipants > 1 ||
        d.bufferAfterMinutes > 0 ||
        d.bonusPayPercent > 0 ||
        d.bonusEarnAmount > 0 ||
        d.description.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final draft = widget.draft;
    final enabled = widget.enabled;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingField(
            controller: widget.titleController,
            labelText: context.l10n.booking_name,
            hintText: context.l10n.booking_service_title_hint,
            textInputAction: TextInputAction.next,
            isEnabled: enabled,
            onChanged: (_) => widget.onDraftChanged(),
          ),
          const SizedBox(height: 14),
          AppSmilePicker(
            controller: widget.emojiController,
            label: context.l10n.booking_emoji_label,
            hintText: context.l10n.booking_select,
            enabled: enabled,
            onChanged: (_) => widget.onDraftChanged(),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BookingField(
                  controller: widget.durationController,
                  labelText: context.l10n.booking_minutes_field,
                  hintText: '30',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_intFormatter],
                  isEnabled: enabled,
                  onChanged: (_) => widget.onDraftChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BookingField(
                  controller: widget.priceController,
                  labelText: context.l10n.booking_price_tenge_label,
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_priceFormatter],
                  isEnabled: enabled,
                  onChanged: (_) => widget.onDraftChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.booking_executors,
            style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          if (widget.selectedExecutors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final executor in widget.selectedExecutors)
                  _ExecutorChip(
                    executor: executor,
                    enabled: enabled,
                    onRemove: widget.onRemoveExecutor == null
                        ? null
                        : () => widget.onRemoveExecutor!(executor.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          AppOutlinedButton(
            text: context.l10n.booking_add_executor,
            height: 48,
            isExpanded: true,
            service: kBookingService,
            onTap: enabled ? widget.onAddExecutor : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.personSearch.icon,
                  size: 18,
                  color: enabled ? colors.textColor : colors.subTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.booking_find_account,
                  style: AppTextStyle.base(
                    16,
                    fontWeight: FontWeight.w700,
                    color: enabled ? colors.textColor : colors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BookingSwitchRow(
            title: context.l10n.booking_show_to_clients,
            subtitle: draft.isActive ? context.l10n.booking_service_active : context.l10n.booking_service_hidden,
            value: draft.isActive,
            enabled: enabled,
            onChanged: enabled ? widget.onActiveChanged : null,
          ),
          const SizedBox(height: 8),
          Material(
            color: colors.surfaceMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _moreOpen = !_moreOpen);
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.booking_more_settings,
                        style: AppTextStyle.base(
                          14,
                          color: colors.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _moreOpen ? AppIcons.arrowUp.icon : AppIcons.arrowDown.icon,
                      size: 22,
                      color: colors.iconMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_moreOpen) ...[
            const SizedBox(height: 14),
            BookingField(
              controller: widget.maxParticipantsController,
              labelText: context.l10n.booking_max_participants,
              hintText: '1',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [_intFormatter],
              isEnabled: enabled,
              onChanged: (_) => widget.onDraftChanged(),
            ),
            const SizedBox(height: 14),
            BookingField(
              controller: widget.bufferAfterController,
              labelText: context.l10n.booking_buffer_after_min,
              hintText: '0',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [_intFormatter],
              isEnabled: enabled && !widget.bufferAfterLocked,
              onChanged: (_) => widget.onDraftChanged(),
            ),
            if (widget.bufferAfterLocked) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.booking_buffer_create_only,
                style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.3),
              ),
            ],
            const SizedBox(height: 14),
            BookingField(
              controller: widget.descriptionController,
              labelText: context.l10n.booking_description_label,
              hintText: context.l10n.booking_optional,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.multiline,
              isEnabled: enabled,
              onChanged: (_) => widget.onDraftChanged(),
            ),
            const SizedBox(height: 14),
            BookingField(
              controller: widget.bonusEarnAmountController,
              labelText: context.l10n.booking_bonuses_per_visit,
              hintText: '0',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [_intFormatter],
              isEnabled: enabled,
              onChanged: (_) => widget.onDraftChanged(),
            ),
            const SizedBox(height: 14),
            BookingField(
              controller: widget.bonusPayPercentController,
              labelText: context.l10n.booking_bonus_pay_percent,
              hintText: '0',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [_intFormatter],
              isEnabled: enabled,
              onChanged: (_) => widget.onDraftChanged(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExecutorChip extends StatelessWidget {
  const _ExecutorChip({
    required this.executor,
    required this.enabled,
    this.onRemove,
  });

  final BookingServiceExecutor executor;
  final bool enabled;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final avatarUrl = executor.avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.soft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: colors.surfaceSoft,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(AppIcons.user.icon, color: colors.iconMuted, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              executor.displayName,
              style: AppTextStyle.base(13, color: colors.textColor, fontWeight: FontWeight.w600),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: enabled ? onRemove : null,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    AppIcons.closeRounded.icon,
                    size: 16,
                    color: enabled ? colors.subTextColor : colors.border,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
