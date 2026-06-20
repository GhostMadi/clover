import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/marker_tags/data/repository/marker_tags_repository.dart';
import 'package:flutter/material.dart';

/// Множественный выбор тегов маркера из справочника `marker_tags`.
class MultiMarkerTags extends StatefulWidget {
  const MultiMarkerTags({
    super.key,
    this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.searchHint = 'Поиск тега',
    this.sheetTitle,
    this.enabled = true,
  });

  final String? label;
  final String hint;

  /// Id выбранных тегов (`marker_tags.id`).
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;

  final String searchHint;
  final String? sheetTitle;
  final bool enabled;

  static const double _fieldRadius = 12;

  @override
  State<MultiMarkerTags> createState() => _MultiMarkerTagsState();
}

class _MultiMarkerTagsState extends State<MultiMarkerTags> {
  final _repository = sl<MarkerTagsRepository>();

  List<MarkerTagModel> _tags = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repository.listAll();
      if (!mounted) return;

      setState(() {
        _tags = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить теги';
      });
    }
  }

  Set<String> _normalizeValues() {
    if (widget.values.isEmpty || _tags.isEmpty) return const {};

    final knownIds = _tags.map((tag) => tag.id).toSet();
    return widget.values.where(knownIds.contains).toSet();
  }

  List<AppMultiSelectGroup<String>> get _groups => MarkerTagModel.toMultiSelectGroups(_tags);

  String? _selectedDisplay() {
    final selected = _normalizeValues();
    if (selected.isEmpty) return null;

    final labels = <String>[];
    for (final tag in _tags) {
      if (selected.contains(tag.id)) labels.add(tag.labelRu);
    }
    if (labels.isEmpty) return null;
    return labels.join(', ');
  }

  Future<void> _openSheet() async {
    if (_tags.isEmpty || !widget.enabled) return;

    final picked = await AppBottomSheet.show<Set<String>>(
      context: context,
      title: widget.sheetTitle ?? widget.label ?? 'Теги маркера',
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 0,
      expandBody: true,
      sheetOuterPadding: EdgeInsets.zero,
      sheetWidth: MediaQuery.sizeOf(context).width,
      content: AppMultiSelectSheetContent<String>(
        searchHint: widget.searchHint,
        groups: _groups,
        options: const [],
        selected: _normalizeValues(),
        confirmLabel: 'Готово',
      ),
    );

    if (!mounted || picked == null) return;
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          Text(_error!, style: AppTextStyle.base(13, color: AppColors.subTextColor)),
        ],
      );
    }

    final emptyHint = _tags.isEmpty ? 'Нет доступных тегов' : widget.hint;
    final display = _selectedDisplay();
    final hasValue = display != null && display.isNotEmpty;
    final canOpen = _tags.isNotEmpty && widget.enabled;

    final field = Material(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(MultiMarkerTags._fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(MultiMarkerTags._fieldRadius),
        onTap: canOpen ? _openSheet : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MultiMarkerTags._fieldRadius),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? display : emptyHint,
                  style: AppTextStyle.base(
                    16,
                    color: hasValue ? AppColors.textColor : AppColors.subTextColor.withValues(alpha: 0.65),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.subTextColor.withValues(alpha: 0.55),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            field,
          ],
        ),
      ),
    );
  }
}
