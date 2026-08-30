import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_smile_picker.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/city/presentation/widget/city_single_select_field.dart';
import 'package:clover/feature/countries/presentation/widget/country_single_select_field.dart';
import 'package:clover/feature/events_page/data/models/events_content_kind.dart';
import 'package:clover/feature/events_page/data/models/events_filter.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/marker_tags/presentation/widget/multi_marker_tags.dart';
import 'package:flutter/material.dart';

abstract final class EventsFilterSheet {
  static Future<EventsFilter?> show(
    BuildContext context, {
    required EventsFilter initial,
    EventsFilterSheetMode mode = EventsFilterSheetMode.feed,
  }) {
    return AppBottomSheet.show<EventsFilter>(
      context: context,
      title: mode == EventsFilterSheetMode.map ? 'Фильтр карты' : 'Фильтр',
      upperCaseTitle: false,
      showCloseButton: true,
      content: _EventsFilterContent(initial: initial, mode: mode),
    );
  }
}

enum EventsFilterSheetMode { feed, map }

enum _EventsDatePreset {
  today,
  tomorrow,
  dayAfterTomorrow,
  week,
  month;

  String get label => switch (this) {
        _EventsDatePreset.today => 'Сегодня',
        _EventsDatePreset.tomorrow => 'Завтра',
        _EventsDatePreset.dayAfterTomorrow => 'Послезавтра',
        _EventsDatePreset.week => 'Неделя',
        _EventsDatePreset.month => 'Месяц',
      };
}

class _EventsFilterContent extends StatefulWidget {
  const _EventsFilterContent({required this.initial, required this.mode});

  final EventsFilter initial;
  final EventsFilterSheetMode mode;

  @override
  State<_EventsFilterContent> createState() => _EventsFilterContentState();
}

class _EventsFilterContentState extends State<_EventsFilterContent> {
  static const _contentKindTabs = [EventsContentKind.all, EventsContentKind.eventsOnly];

  static const _eventEmojis = <String>[
    '🎉',
    '🎈',
    '🎵',
    '🎤',
    '🎸',
    '🎭',
    '🎬',
    '🎨',
    '🏃',
    '⚽',
    '🏀',
    '🎯',
    '🍕',
    '☕',
    '🍻',
    '💃',
    '🪩',
    '📍',
    '🗺️',
    '✨',
    '🔥',
    '⭐',
    '🌟',
    '💫',
    '🎪',
    '🎡',
    '🎢',
    '🎮',
    '🌸',
    '🌿',
    '🌙',
    '☀️',
    '🌈',
  ];

  late EventsContentKind _contentKind;
  late final TextEditingController _emojiController;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _countryCode;
  String? _cityCode;
  Set<String> _selectedTagIds = const {};

  bool get _isMapMode => widget.mode == EventsFilterSheetMode.map;

  bool get _showEventFilters => _isMapMode || _contentKind == EventsContentKind.eventsOnly;

  @override
  void initState() {
    super.initState();
    _contentKind = _isMapMode ? EventsContentKind.eventsOnly : widget.initial.contentKind;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
    _countryCode = widget.initial.countryCode;
    _cityCode = widget.initial.cityCode;
    _selectedTagIds = Set<String>.of(widget.initial.tagIds);
    _emojiController = TextEditingController(text: widget.initial.emoji ?? '');
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String code) {
    setState(() {
      _countryCode = code;
      _cityCode = null;
    });
  }

  void _onContentKindChanged(EventsContentKind kind) {
    if (_contentKind == kind) return;
    setState(() {
      _contentKind = kind;
      if (kind == EventsContentKind.all) {
        _dateFrom = null;
        _dateTo = null;
        _emojiController.clear();
        _selectedTagIds = const {};
      }
    });
  }

  void _applyDatePreset(_EventsDatePreset preset) {
    final today = _dateOnly(DateTime.now());
    late DateTime from;
    late DateTime to;

    switch (preset) {
      case _EventsDatePreset.today:
        from = today;
        to = today;
      case _EventsDatePreset.tomorrow:
        from = today.add(const Duration(days: 1));
        to = from;
      case _EventsDatePreset.dayAfterTomorrow:
        from = today.add(const Duration(days: 2));
        to = from;
      case _EventsDatePreset.week:
        from = today;
        to = today.add(const Duration(days: 6));
      case _EventsDatePreset.month:
        from = today;
        to = today.add(const Duration(days: 29));
    }

    setState(() {
      _dateFrom = from;
      _dateTo = to;
    });
  }

  bool _matchesPreset(_EventsDatePreset preset) {
    if (_dateFrom == null || _dateTo == null) return false;

    final today = _dateOnly(DateTime.now());
    final from = _dateOnly(_dateFrom!);
    final to = _dateOnly(_dateTo!);

    return switch (preset) {
      _EventsDatePreset.today => from == today && to == today,
      _EventsDatePreset.tomorrow => () {
          final day = today.add(const Duration(days: 1));
          return from == day && to == day;
        }(),
      _EventsDatePreset.dayAfterTomorrow => () {
          final day = today.add(const Duration(days: 2));
          return from == day && to == day;
        }(),
      _EventsDatePreset.week => from == today && to == today.add(const Duration(days: 6)),
      _EventsDatePreset.month => from == today && to == today.add(const Duration(days: 29)),
    };
  }

  void _reset() {
    setState(() {
      _contentKind = EventsContentKind.eventsOnly;
      _dateFrom = null;
      _dateTo = null;
      _countryCode = null;
      _cityCode = null;
      _emojiController.clear();
      _selectedTagIds = const {};
    });
  }

  void _apply() {
    final emoji = _emojiController.text.trim();
    final contentKind = _isMapMode ? EventsContentKind.eventsOnly : _contentKind;
    Navigator.pop(
      context,
      EventsFilter(
        contentKind: contentKind,
        dateFrom: _showEventFilters ? _dateFrom : null,
        dateTo: _showEventFilters ? _dateTo : null,
        countryCode: _countryCode,
        cityCode: _cityCode,
        emoji: _showEventFilters && emoji.isNotEmpty ? emoji : null,
        tagIds: _showEventFilters ? Set<String>.of(_selectedTagIds) : const {},
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CountrySingleSelectField(
          label: 'Страна',
          hint: 'Выберите страну',
          value: _countryCode,
          onChanged: _onCountryChanged,
        ),
        const SizedBox(height: 12),
        CitySingleSelectField(
          label: 'Город',
          hint: 'Выберите город',
          countryCode: _countryCode,
          value: _cityCode,
          onChanged: (code) => setState(() => _cityCode = code),
        ),
        const SizedBox(height: 16),
        if (!_isMapMode) ...[
          AppTab(
            tabs: _contentKindTabs.map((kind) => kind.label).toList(growable: false),
            currentIndex: _contentKindTabs.indexOf(_contentKind),
            onTabChanged: (index) => _onContentKindChanged(_contentKindTabs[index]),
          ),
        ],
        if (_showEventFilters) ...[
          if (!_isMapMode) const SizedBox(height: 16),
          Text(
            'Дни ивента',
            style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _EventsDatePreset.values)
                _DatePresetChip(
                  label: preset.label,
                  selected: _matchesPreset(preset),
                  onTap: () => _applyDatePreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppDatePicker(
                  label: 'С',
                  hint: 'Начало',
                  value: _dateFrom,
                  lastDate: _dateTo,
                  onChanged: (value) => setState(() {
                    _dateFrom = _dateOnly(value);
                    if (_dateTo != null && _dateTo!.isBefore(_dateFrom!)) {
                      _dateTo = _dateFrom;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppDatePicker(
                  label: 'По',
                  hint: 'Конец',
                  value: _dateTo,
                  firstDate: _dateFrom,
                  onChanged: (value) => setState(() {
                    _dateTo = _dateOnly(value);
                    if (_dateFrom != null && _dateFrom!.isAfter(_dateTo!)) {
                      _dateFrom = _dateTo;
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSmilePicker(
            controller: _emojiController,
            label: 'Эмодзи ивента',
            hintText: 'Любое — оставьте пустым',
            emojis: _eventEmojis,
            shuffleStrip: false,
            maxLength: 1,
          ),
          const SizedBox(height: 16),
          MultiMarkerTags(
            label: 'Теги маркера',
            hint: 'Любые — оставьте пустым',
            sheetTitle: 'Теги маркера',
            searchHint: 'Поиск тега',
            values: _selectedTagIds,
            excludeGroupKeys: const {MarkerTagGroupKey.account},
            onChanged: (value) => setState(() => _selectedTagIds = value),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(text: 'Сбросить', height: 48, onTap: _reset),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(text: 'Применить', height: 48, onTap: _apply),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePresetChip extends StatelessWidget {
  const _DatePresetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceSoftGreen.withValues(alpha: 0.7) : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.borderCardGreen : AppColors.borderSoft,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.base(
              13,
              color: selected ? AppColors.primary : AppColors.textColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
