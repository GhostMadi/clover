import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_executor_pick.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_service_editor_cubit.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_service_form.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/widget/booking_staff_profile_search_sheet.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingServiceCreatePage extends StatefulWidget {
  const BookingServiceCreatePage({super.key});

  @override
  State<BookingServiceCreatePage> createState() => _BookingServiceCreatePageState();
}

class _BookingServiceCreatePageState extends State<BookingServiceCreatePage> {
  late final BookingServiceEditorCubit _cubit;
  late final BookingStaffRepository _staffRepository;
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _emojiController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _maxParticipantsController = TextEditingController(text: '1');
  final _bufferAfterController = TextEditingController(text: '0');
  final _bonusPayPercentController = TextEditingController(text: '0');
  final _bonusEarnAmountController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  BookingServiceDraft _draft = const BookingServiceDraft();

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingServiceEditorCubit>()..initForCreate();
    _staffRepository = sl<BookingStaffRepository>();
    _syncDraftFromControllers();
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

  Set<String> _excludeProfileIds() {
    return {
      for (final pick in _draft.executors)
        if (pick.profileId != null && pick.profileId!.trim().isNotEmpty) pick.profileId!.trim(),
    };
  }

  Future<void> _addExecutor() async {
    final profile = await BookingStaffProfileSearchSheet.show(
      context,
      repository: _staffRepository,
      excludeProfileIds: _excludeProfileIds(),
    );
    if (profile == null || !mounted) return;

    if (_draft.executors.any((pick) => pick.profileId == profile.id)) {
      AppSnackBar.show(context, message: 'Этот мастер уже добавлен', kind: AppSnackBarKind.error);
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        executors: [..._draft.executors, BookingExecutorPick.fromProfile(profile)],
      );
    });
  }

  void _removeExecutor(String key) {
    setState(() {
      _draft = _draft.copyWith(
        executors: _draft.executors.where((pick) => pick.key != key).toList(),
      );
    });
  }

  Future<void> _submit() async {
    if (!_draft.isValid) return;
    final service = await _cubit.create(_draft);
    if (!mounted || service == null) {
      final message = _cubit.state.maybeMap(error: (s) => s.message, orElse: () => null);
      if (message != null && mounted) {
        AppSnackBar.show(context, message: BookingException.from(message).userMessage, kind: AppSnackBarKind.error);
      }
      return;
    }
    AppSnackBar.show(context, message: 'Услуга добавлена', kind: AppSnackBarKind.success);
    context.router.maybePop(service);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingServiceEditorCubit, BookingServiceEditorState>(
      bloc: _cubit,
      builder: (context, state) {
        final isSubmitting = state.maybeMap(submitting: (_) => true, orElse: () => false);
        final selected = [for (final pick in _draft.executors) pick.toDisplayExecutor()];

        return BookingScreenShell(
          title: 'Новая услуга',
          compactBar: true,
          isLoading: isSubmitting,
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
    );
  }
}
