import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_create/data/mock/booking_services_mock_data.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/booking/booking_create/presentation/widget/booking_service_form.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingServiceEditPage extends StatefulWidget {
  const BookingServiceEditPage({super.key, required this.service});

  final BookingService service;

  @override
  State<BookingServiceEditPage> createState() => _BookingServiceEditPageState();
}

class _BookingServiceEditPageState extends State<BookingServiceEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _emojiController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _bufferAfterController;
  late final TextEditingController _descriptionController;

  late BookingServiceDraft _draft;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _draft = BookingServiceDraft.fromService(widget.service);
    _titleController = TextEditingController(text: _draft.title);
    _durationController = TextEditingController(text: '${_draft.durationMinutes}');
    _emojiController = TextEditingController(text: _draft.emojiText);
    _priceController = TextEditingController(text: _formatPrice(_draft.price));
    _maxParticipantsController = TextEditingController(text: '${_draft.maxParticipants}');
    _bufferAfterController = TextEditingController(text: '${_draft.bufferAfterMinutes}');
    _descriptionController = TextEditingController(text: _draft.description);
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

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) return '${price.toInt()}';
    return price.toString();
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

    final updated = _draft.toService(id: widget.service.id);
    AppSnackBar.show(context, message: 'Услуга сохранена', kind: AppSnackBarKind.success);
    context.router.maybePop(updated);
  }

  Future<void> _openSettings() async {
    await context.router.push<bool>(const BookingScheduleSettingsRoute());
  }

  @override
  Widget build(BuildContext context) {
    return BookingScreenShell(
      title: 'Редактирование',
      compactBar: true,
      isLoading: _submitting,
      showSettings: true,
      onSettingsTap: _openSettings,
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
        bufferAfterLocked: true,
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
