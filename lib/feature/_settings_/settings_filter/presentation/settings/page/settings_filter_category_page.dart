import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Детальная страница категории фильтра витрины (создать / редактировать).
@RoutePage()
class SettingsFilterCategoryPage extends StatefulWidget {
  const SettingsFilterCategoryPage({
    super.key,
    this.categoryId,
    this.initialName,
    this.initialValues = const [],
  });

  /// Пусто / null — создание новой категории.
  final String? categoryId;
  final String? initialName;
  final List<String> initialValues;

  @override
  State<SettingsFilterCategoryPage> createState() => _SettingsFilterCategoryPageState();
}

class _SettingsFilterCategoryPageState extends State<SettingsFilterCategoryPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late List<String> _values;
  var _saving = false;

  bool get _isCreate {
    final id = widget.categoryId?.trim();
    return id == null || id.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _valueController = TextEditingController();
    _values = [...widget.initialValues];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    return !_saving && name.isNotEmpty && _values.isNotEmpty;
  }

  void _addValue() {
    final value = _valueController.text.trim();
    if (value.isEmpty) return;
    if (_values.any((v) => v.toLowerCase() == value.toLowerCase())) {
      _valueController.clear();
      return;
    }
    setState(() {
      _values = [..._values, value];
      _valueController.clear();
    });
  }

  void _removeValue(String value) {
    setState(() => _values = _values.where((v) => v != value).toList());
  }

  void _save() {
    if (!_canSave) return;
    setState(() => _saving = true);
    context.router.pop(
      FilterCategory(
        id: widget.categoryId?.trim() ?? '',
        name: _nameController.text.trim(),
        values: List.unmodifiable(_values),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(kResourcesService);
    final title = _isCreate ? context.l10n.settings_new_category : (widget.initialName?.trim().isNotEmpty == true
        ? widget.initialName!.trim()
        : context.l10n.settings_category);

    return SettingsScreenShell(
      title: title,
      service: kResourcesService,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
          children: [
            AppField(
              controller: _nameController,
              labelText: context.l10n.settings_category_name,
              hintText: context.l10n.settings_category_name_hint,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              service: kResourcesService,
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.settings_values,
              style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppField(
                    controller: _valueController,
                    hintText: context.l10n.settings_values_hint,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    service: kResourcesService,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: accent.soft,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _addValue,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(AppIcons.addRounded.icon, color: accent.icon),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_values.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.soft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.6)),
                ),
                child: Text(
                  context.l10n.settings_add_one_value,
                  style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w500),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in _values)
                    InputChip(
                      label: Text(
                        value,
                        style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600),
                      ),
                      deleteIcon: Icon(AppIcons.closeRounded.icon, size: 18, color: accent.icon),
                      onDeleted: () => _removeValue(value),
                      backgroundColor: accent.soft,
                      side: BorderSide(color: accent.ctaBorder.withValues(alpha: 0.7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            AppButton(
              text: _isCreate ? context.l10n.settings_save_category : context.l10n.settings_save_changes,
              isExpanded: true,
              service: kResourcesService,
              onTap: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
