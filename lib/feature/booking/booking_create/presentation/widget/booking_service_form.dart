import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingServiceForm extends StatelessWidget {
  const BookingServiceForm({
    super.key,
    required this.draft,
    required this.titleController,
    required this.durationController,
    required this.emojiController,
    required this.priceController,
    required this.maxParticipantsController,
    required this.bufferAfterController,
    required this.descriptionController,
    required this.onDraftChanged,
    this.executors = const [],
    this.onActiveChanged,
    this.onExecutorChanged,
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
  final TextEditingController descriptionController;
  final VoidCallback onDraftChanged;
  final List<BookingServiceExecutor> executors;
  final ValueChanged<bool>? onActiveChanged;
  final ValueChanged<String?>? onExecutorChanged;
  final bool enabled;
  final bool bufferAfterLocked;

  static final _intFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _priceFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  @override
  Widget build(BuildContext context) {
    final executorOptions = [
      const AppSingleSelectOption<String?>(value: null, label: 'Не назначен'),
      for (final executor in executors)
        AppSingleSelectOption<String?>(value: executor.id, label: executor.displayLabel),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            controller: titleController,
            labelText: 'Название',
            hintText: 'Например, Стрижка мужская',
            textInputAction: TextInputAction.next,
            isEnabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          const SizedBox(height: 16),
          AppSmilePicker(
            controller: emojiController,
            label: 'Эмодзи',
            hintText: 'Выберите один эмодзи',
            enabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          const SizedBox(height: 16),
          AppField(
            controller: durationController,
            labelText: 'Длительность (мин)',
            hintText: '30',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [_intFormatter],
            isEnabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          const SizedBox(height: 16),
          AppField(
            controller: priceController,
            labelText: 'Цена (₸)',
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [_priceFormatter],
            isEnabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          const SizedBox(height: 16),
          AppField(
            controller: maxParticipantsController,
            labelText: 'Макс. участников',
            hintText: '1',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [_intFormatter],
            isEnabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          const SizedBox(height: 16),
          AppField(
            controller: bufferAfterController,
            labelText: 'Буфер после (мин)',
            hintText: '0',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [_intFormatter],
            isEnabled: enabled && !bufferAfterLocked,
            onChanged: (_) => onDraftChanged(),
          ),
          if (bufferAfterLocked) ...[
            const SizedBox(height: 6),
            Text(
              'Буфер задаётся только при создании услуги',
              style: AppTextStyle.base(12, color: AppColors.subTextColor, height: 1.3),
            ),
          ],
          const SizedBox(height: 16),
          AppField(
            controller: descriptionController,
            labelText: 'Описание',
            hintText: 'Необязательно',
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.multiline,
            isEnabled: enabled,
            onChanged: (_) => onDraftChanged(),
          ),
          if (executors.isNotEmpty) ...[
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: AppSingleSelect<String?>(
                  label: 'Исполнитель',
                  hint: 'Назначить исполнителя',
                  sheetTitle: 'Исполнитель услуги',
                  searchHint: 'Поиск по имени',
                  options: executorOptions,
                  value: draft.executorId,
                  onChanged: (value) => onExecutorChanged?.call(value),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          AppSwitchRow(
            title: 'Активна',
            subtitle: 'Неактивные услуги не показываются клиентам',
            value: draft.isActive,
            enabled: enabled,
            onChanged: enabled ? onActiveChanged : null,
          ),
        ],
      ),
    );
  }
}
