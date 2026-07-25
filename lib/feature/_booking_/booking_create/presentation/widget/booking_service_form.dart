import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      bloc: sl<ProfileCubit>(),
      builder: (context, profileState) {
        final bonusProgramEnabled = profileState.maybeMap(
          loaded: (s) => s.profile.isBonusProgramActive,
          orElse: () => false,
        );

        return _BookingServiceFormBody(
          draft: draft,
          titleController: titleController,
          durationController: durationController,
          emojiController: emojiController,
          priceController: priceController,
          maxParticipantsController: maxParticipantsController,
          bufferAfterController: bufferAfterController,
          bonusPayPercentController: bonusPayPercentController,
          bonusEarnAmountController: bonusEarnAmountController,
          descriptionController: descriptionController,
          onDraftChanged: onDraftChanged,
          selectedExecutors: selectedExecutors,
          onRemoveExecutor: onRemoveExecutor,
          onAddExecutor: onAddExecutor,
          onActiveChanged: onActiveChanged,
          enabled: enabled,
          bufferAfterLocked: bufferAfterLocked,
          bonusProgramEnabled: bonusProgramEnabled,
        );
      },
    );
  }
}

class _BookingServiceFormBody extends StatelessWidget {
  const _BookingServiceFormBody({
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
    required this.bonusProgramEnabled,
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
  final bool bonusProgramEnabled;

  static final _intFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _priceFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  @override
  Widget build(BuildContext context) {
    final fieldsEnabled = enabled && bonusProgramEnabled;

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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Бонусы',
                  style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  bonusProgramEnabled
                      ? 'Настройки начисления и оплаты бонусами за эту услугу'
                      : 'Включите бонусную программу в настройках, чтобы настроить бонусы',
                  style: AppTextStyle.base(12, color: AppColors.subTextColor, height: 1.3),
                ),
                const SizedBox(height: 12),
                AppField(
                  controller: bonusEarnAmountController,
                  labelText: 'Бонусов за визит',
                  hintText: '50',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_intFormatter],
                  isEnabled: fieldsEnabled,
                  onChanged: (_) => onDraftChanged(),
                ),
                const SizedBox(height: 14),
                AppField(
                  controller: bonusPayPercentController,
                  labelText: 'Оплата бонусами (%)',
                  hintText: '20',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_intFormatter],
                  isEnabled: fieldsEnabled,
                  onChanged: (_) => onDraftChanged(),
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 16),
          Text(
            'Исполнители',
            style: AppTextStyle.base(14, color: AppColors.textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Один сервис — несколько мастеров. Найдите аккаунты из приложения.',
            style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.35),
          ),
          if (selectedExecutors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final executor in selectedExecutors)
                  _ExecutorChip(
                    executor: executor,
                    enabled: enabled,
                    onRemove: onRemoveExecutor == null ? null : () => onRemoveExecutor!(executor.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          AppOutlinedButton(
            text: 'Добавить исполнителя',
            height: 48,
            isExpanded: true,
            onTap: enabled ? onAddExecutor : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 18,
                  color: enabled ? AppColors.textColor : AppColors.subTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Найти аккаунт',
                  style: AppTextStyle.base(
                    16,
                    fontWeight: FontWeight.w700,
                    color: enabled ? AppColors.textColor : AppColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
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
    final avatarUrl = executor.avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftGreen.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderCardGreen.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceSoft,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.iconMuted, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              executor.displayName,
              style: AppTextStyle.base(13, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: enabled ? onRemove : null,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: enabled ? AppColors.subTextColor : AppColors.border,
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
