import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:flutter/material.dart';

List<String> _presetReasons(BuildContext context) => [
      context.l10n.booking_cancel_service_preset_plans,
      context.l10n.booking_cancel_service_preset_master,
      context.l10n.booking_cancel_service_preset_stopped,
      context.l10n.booking_cancel_service_preset_updating,
    ];

/// Шторка отмены услуги: готовые формулировки + своё сообщение.
Future<String?> showBookingServiceCancelSheet(
  BuildContext context, {
  required String serviceTitle,
}) {
  return AppBottomSheet.show<String>(
    context: context,
    title: context.l10n.booking_cancel_service,
    showCloseButton: true,
    content: _BookingServiceCancelSheetBody(serviceTitle: serviceTitle),
  );
}

class _BookingServiceCancelSheetBody extends StatefulWidget {
  const _BookingServiceCancelSheetBody({required this.serviceTitle});

  final String serviceTitle;

  @override
  State<_BookingServiceCancelSheetBody> createState() => _BookingServiceCancelSheetBodyState();
}

class _BookingServiceCancelSheetBodyState extends State<_BookingServiceCancelSheetBody> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _applyPreset(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.collapsed(offset: text.length);
  }

  void _confirm() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _messageController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.booking_service_cancel_body(widget.serviceTitle),
          style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.booking_ready_messages,
          style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presetReasons(context))
              _PresetChip(
                label: preset,
                onTap: () => _applyPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppField(
          controller: _messageController,
          labelText: context.l10n.booking_reason,
          hintText: context.l10n.booking_reason_hint,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: context.l10n.common_back,
                height: 48,
                isExpanded: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: canConfirm ? context.colors.functionalSoftRedIcon : context.colors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: canConfirm ? _confirm : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canConfirm ? context.colors.functionalSoftRedIcon : context.colors.border,
                      ),
                    ),
                    child: Text(
                      context.l10n.booking_cancel_service,
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w700,
                        color: canConfirm ? context.colors.textInverse : context.colors.subTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.functionalSoftRed,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.borderCardRed.withValues(alpha: 0.85)),
          ),
          child: Text(
            label,
            style: AppTextStyle.base(13, color: context.colors.destructive, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
      ),
    );
  }
}
