import 'package:auto_route/auto_route.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_create/data/mock/booking_services_mock_data.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_service_form.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingServiceCreatePage extends StatefulWidget {
  const BookingServiceCreatePage({super.key});

  @override
  State<BookingServiceCreatePage> createState() => _BookingServiceCreatePageState();
}

class _BookingServiceCreatePageState extends State<BookingServiceCreatePage> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _emojiController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _maxParticipantsController = TextEditingController(text: '1');
  final _bufferAfterController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  BookingServiceDraft _draft = const BookingServiceDraft();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _syncDraftFromControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _emojiController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _bufferAfterController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _parseInt(String raw, {required int fallback}) {
    return int.tryParse(raw.trim()) ?? fallback;
  }

  double _parsePrice(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;
  }

  void _syncDraftFromControllers() {
    setState(() {
      _draft = _draft.copyWith(
        title: _titleController.text,
        durationMinutes: _parseInt(_durationController.text, fallback: 0),
        emojiText: _emojiController.text,
        price: _parsePrice(_priceController.text),
        maxParticipants: _parseInt(_maxParticipantsController.text, fallback: 1),
        bufferAfterMinutes: _parseInt(_bufferAfterController.text, fallback: 0),
        description: _descriptionController.text,
      );
    });
  }

  Future<void> _submit() async {
    if (!_draft.isValid || _submitting) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final service = _draft.toService(id: DateTime.now().millisecondsSinceEpoch.toString());
    AppSnackBar.show(context, message: 'Услуга добавлена', kind: AppSnackBarKind.success);
    context.router.maybePop(service);
  }

  @override
  Widget build(BuildContext context) {
    return BookingScreenShell(
      title: 'Новая услуга',
      compactBar: true,
      isLoading: _submitting,
      showSave: true,
      canSave: _draft.isValid,
      onSaveTap: _submit,
      body: BookingServiceForm(
        draft: _draft,
        titleController: _titleController,
        durationController: _durationController,
        emojiController: _emojiController,
        priceController: _priceController,
        maxParticipantsController: _maxParticipantsController,
        bufferAfterController: _bufferAfterController,
        descriptionController: _descriptionController,
        executors: BookingServicesMockData.executors,
        enabled: !_submitting,
        onDraftChanged: _syncDraftFromControllers,
        onExecutorChanged: (value) {
          setState(() {
            _draft = value == null
                ? _draft.copyWith(clearExecutorId: true)
                : _draft.copyWith(executorId: value);
          });
        },
        onActiveChanged: (value) {
          setState(() => _draft = _draft.copyWith(isActive: value));
        },
      ),
    );
  }
}
