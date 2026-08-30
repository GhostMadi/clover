import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';

/// Итоговые данные перед созданием маркера на сервере.
class MarkerCreateComposeResult {
  const MarkerCreateComposeResult({
    required this.media,
    required this.title,
    required this.description,
    required this.textEmoji,
    this.tagIds = const {},
    this.filterValues = const {},
    this.location,
    this.eventPeriod,
  });

  final List<AppImageEditorResult> media;

  /// Заголовок поста (как в [PostCreateComposeResult]).
  final String title;

  /// Описание поста.
  final String description;

  /// `markers.text_emoji`
  final String textEmoji;

  /// `marker_tag_links.tag_id`
  final Set<String> tagIds;

  /// Ключи `category_id:label` из настроек фильтров профиля.
  final Set<String> filterValues;

  /// Выбранное местоположение (id, адреса, geo, страна/город).
  final LocationModel? location;

  /// Начало и конец события.
  final AppDateTimeRange? eventPeriod;

  DateTime? get eventTime => eventPeriod?.start;

  DateTime? get eventEndTime => eventPeriod?.end;

  Duration? get eventDuration => eventPeriod?.duration;
}
