import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_profile_/edit_profile/data/edit_profile_username_policy.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class EditProfileUsernameSheet {
  static Future<ProfileNewModel?> show(
    BuildContext context, {
    required ProfileNewModel profile,
    required String currentUsername,
    required Future<ProfileNewModel?> Function(String username) onSave,
  }) {
    return AppBottomSheet.show<ProfileNewModel>(
      context: context,
      title: 'Никнейм',
      upperCaseTitle: false,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _EditProfileUsernameSheetBody(
        profile: profile,
        initialUsername: currentUsername,
        onSave: onSave,
      ),
    );
  }
}

class _EditProfileUsernameSheetBody extends StatefulWidget {
  const _EditProfileUsernameSheetBody({
    required this.profile,
    required this.initialUsername,
    required this.onSave,
  });

  final ProfileNewModel profile;
  final String initialUsername;
  final Future<ProfileNewModel?> Function(String username) onSave;

  @override
  State<_EditProfileUsernameSheetBody> createState() => _EditProfileUsernameSheetBodyState();
}

class _EditProfileUsernameSheetBodyState extends State<_EditProfileUsernameSheetBody> {
  late final TextEditingController _controller;
  late EditProfileUsernamePolicy _policy;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _policy = EditProfileUsernamePolicy.fromProfile(widget.profile);
    _controller = TextEditingController(text: widget.initialUsername);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String get _draft => _controller.text.trim();

  bool get _hasChanges => _draft.toLowerCase() != widget.initialUsername.trim().toLowerCase();

  bool get _isValidFormat => _draft.isNotEmpty && RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(_draft);

  bool get _canSave => _policy.canChange && _hasChanges && _isValidFormat && !_isSubmitting;

  void _cancel() {
    if (_isSubmitting) return;
    Navigator.of(context).pop();
  }

  Future<void> _saveOrNotify() async {
    if (_isSubmitting) return;

    if (_canSave) {
      setState(() => _isSubmitting = true);
      final profile = await widget.onSave(_draft);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (profile != null) {
        Navigator.of(context).pop(profile);
      }
      return;
    }

    if (!_policy.canChange) {
      AppSnackBar.show(
        context,
        message: _policy.statusHint ?? 'Смена никнейма сейчас недоступна',
        kind: AppSnackBarKind.info,
      );
      return;
    }
    if (!_isValidFormat) {
      AppSnackBar.show(
        context,
        message: 'Никнейм может содержать только латиницу, цифры, «_» и «.»',
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _policy.statusHint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(
            hint,
            style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
          ),
          const SizedBox(height: 12),
        ],
        AppField(
          controller: _controller,
          labelText: 'Никнейм',
          hintText: 'username',
          prefixIcon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.done,
          isEnabled: _policy.canChange && !_isSubmitting,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Отмена',
                isExpanded: true,
                onTap: _cancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Сохранить',
                isExpanded: true,
                isLoading: _isSubmitting,
                interactive: _canSave,
                onTap: _saveOrNotify,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
