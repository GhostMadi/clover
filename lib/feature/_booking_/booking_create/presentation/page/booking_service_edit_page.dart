import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_executor_pick.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_service_editor_cubit.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_service_form.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_staff_profile_search_sheet.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingServiceEditPage extends StatefulWidget {
  const BookingServiceEditPage({super.key, required this.service});

  final BookingService service;

  @override
  State<BookingServiceEditPage> createState() => _BookingServiceEditPageState();
}

class _BookingServiceEditPageState extends State<BookingServiceEditPage> {
  late final BookingServiceEditorCubit _cubit;
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _emojiController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _bufferAfterController;
  late final TextEditingController _bonusPayPercentController;
  late final TextEditingController _bonusEarnAmountController;
  late final TextEditingController _descriptionController;

  late BookingServiceDraft _draft;
  bool _hydratedExecutors = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingServiceEditorCubit>()..loadStaff();
    _draft = BookingServiceDraft.fromService(widget.service);
    _titleController = TextEditingController(text: _draft.title);
    _durationController = TextEditingController(text: '${_draft.durationMinutes}');
    _emojiController = TextEditingController(text: _draft.emojiText);
    _priceController = TextEditingController(text: _formatPrice(_draft.price));
    _maxParticipantsController = TextEditingController(text: '${_draft.maxParticipants}');
    _bufferAfterController = TextEditingController(text: '${_draft.bufferAfterMinutes}');
    _bonusPayPercentController = TextEditingController(text: '${_draft.bonusPayPercent}');
    _bonusEarnAmountController = TextEditingController(text: '${_draft.bonusEarnAmount}');
    _descriptionController = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _cubit.close();
    _titleController.dispose();
    _durationController.dispose();
    _emojiController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _bufferAfterController.dispose();
    _bonusPayPercentController.dispose();
    _bonusEarnAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) return '${price.toInt()}';
    return price.toString();
  }

  int _parseInt(String raw, {required int fallback}) => int.tryParse(raw.trim()) ?? fallback;

  double _parsePrice(String raw) => double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  void _syncDraftFromControllers() {
    setState(() {
      _draft = _draft.copyWith(
        title: _titleController.text,
        durationMinutes: _parseInt(_durationController.text, fallback: 0),
        emojiText: _emojiController.text,
        price: _parsePrice(_priceController.text),
        maxParticipants: _parseInt(_maxParticipantsController.text, fallback: 1),
        bufferAfterMinutes: _parseInt(_bufferAfterController.text, fallback: 0),
        bonusPayPercent: _parseInt(_bonusPayPercentController.text, fallback: 0).clamp(0, 100),
        bonusEarnAmount: _parseInt(_bonusEarnAmountController.text, fallback: 0),
        description: _descriptionController.text,
      );
    });
  }

  void _hydrateExecutors(List<BookingServiceExecutor> staff) {
    if (_hydratedExecutors) return;
    _hydratedExecutors = true;

    final byId = {for (final person in staff) person.id: person};
    final hydrated = [
      for (final pick in _draft.executors)
        if (pick.staffId != null && byId[pick.staffId] != null)
          BookingExecutorPick.fromStaff(byId[pick.staffId]!)
        else
          pick,
    ];

    if (!mounted) return;
    setState(() => _draft = _draft.copyWith(executors: hydrated));
  }

  Set<String> _excludeProfileIds() {
    return {
      for (final pick in _draft.executors)
        if (pick.profileId != null && pick.profileId!.trim().isNotEmpty) pick.profileId!.trim(),
    };
  }

  Future<void> _addExecutor() async {
    final profile = await BookingStaffProfileSearchSheet.show(
      context,
      excludeProfileIds: _excludeProfileIds(),
    );
    if (profile == null || !mounted) return;

    if (_draft.executors.any((pick) => pick.profileId == profile.id)) {
      AppSnackBar.show(context, message: 'Этот мастер уже добавлен', kind: AppSnackBarKind.error);
      return;
    }

    setState(() {
      _draft = _draft.copyWith(executors: [..._draft.executors, BookingExecutorPick.fromProfile(profile)]);
    });
  }

  void _removeExecutor(String key) {
    setState(() {
      _draft = _draft.copyWith(executors: _draft.executors.where((pick) => pick.key != key).toList());
    });
  }

  Future<void> _submit() async {
    if (!_draft.isValid) return;
    final updated = await _cubit.update(widget.service.id, _draft);
    if (!mounted || updated == null) {
      final message = _cubit.state.maybeMap(error: (s) => s.message, orElse: () => null);
      if (message != null && mounted) {
        AppSnackBar.show(
          context,
          message: BookingException.from(message).userMessage,
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }
    AppSnackBar.show(context, message: 'Услуга сохранена', kind: AppSnackBarKind.success);
    context.router.maybePop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingServiceEditorCubit, BookingServiceEditorState>(
      bloc: _cubit,
      listenWhen: (prev, next) => next.maybeMap(ready: (_) => true, orElse: () => false),
      listener: (context, state) {
        state.mapOrNull(ready: (s) => _hydrateExecutors(s.staff));
      },
      child: BlocBuilder<BookingServiceEditorCubit, BookingServiceEditorState>(
        bloc: _cubit,
        builder: (context, state) {
          final isSubmitting = state.maybeMap(submitting: (_) => true, orElse: () => false);
          final selected = [for (final pick in _draft.executors) pick.toDisplayExecutor()];

          return BookingScreenShell(
            title: 'Редактирование',
            compactBar: true,
            isLoading: isSubmitting || state.maybeMap(loading: (_) => true, orElse: () => false),
            showSave: true,
            canSave: _draft.isValid && !isSubmitting,
            onSaveTap: _submit,
            body: state.maybeMap(
              error: (s) => Center(child: Text(s.message)),
              orElse: () => BookingServiceForm(
                draft: _draft,
                titleController: _titleController,
                durationController: _durationController,
                emojiController: _emojiController,
                priceController: _priceController,
                maxParticipantsController: _maxParticipantsController,
                bufferAfterController: _bufferAfterController,
                bonusPayPercentController: _bonusPayPercentController,
                bonusEarnAmountController: _bonusEarnAmountController,
                descriptionController: _descriptionController,
                selectedExecutors: selected,
                enabled: !isSubmitting,
                bufferAfterLocked: true,
                onDraftChanged: _syncDraftFromControllers,
                onAddExecutor: _addExecutor,
                onRemoveExecutor: _removeExecutor,
                onActiveChanged: (value) {
                  setState(() => _draft = _draft.copyWith(isActive: value));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
