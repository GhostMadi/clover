import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:flutter/material.dart';

const _presetReasons = [
  'Планы изменились — не смогу прийти',
  'Перепутал время или дату',
  'Запишусь на другое время',
  'Больше не нужна эта услуга',
];

/// Шторка отмены записи клиентом.
Future<String?> showMyBookingCancelSheet(
  BuildContext context, {
  required String serviceTitle,
  required String hostDisplayName,
}) {
  return AppBottomSheet.show<String>(
    context: context,
    title: 'Отменить запись',
    showCloseButton: true,
    content: _MyBookingCancelSheetBody(
      serviceTitle: serviceTitle,
      hostDisplayName: hostDisplayName,
    ),
  );
}

class _MyBookingCancelSheetBody extends StatefulWidget {
  const _MyBookingCancelSheetBody({
    required this.serviceTitle,
    required this.hostDisplayName,
  });

  final String serviceTitle;
  final String hostDisplayName;

  @override
  State<_MyBookingCancelSheetBody> createState() => _MyBookingCancelSheetBodyState();
}

class _MyBookingCancelSheetBodyState extends State<_MyBookingCancelSheetBody> {
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
          '«${widget.serviceTitle}» у ${widget.hostDisplayName} будет отменена. Слот освободится для других клиентов.',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Готовые сообщения',
          style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presetReasons)
              _PresetChip(label: preset, onTap: () => _applyPreset(preset)),
          ],
        ),
        const SizedBox(height: 16),
        AppField(
          controller: _messageController,
          labelText: 'Причина',
          hintText: 'Напишите своё сообщение или выберите выше',
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Назад',
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
                      'Отменить запись',
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
