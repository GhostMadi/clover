import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';

/// Итоговые данные перед публикацией: пост + маркер на карте.
class PostCreateComposeResult {
  const PostCreateComposeResult({
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
  final String title;
  final String description;
  final String textEmoji;
  final Set<String> tagIds;
  final Set<String> filterValues;
  final LocationModel? location;
  final AppDateTimeRange? eventPeriod;

  DateTime? get eventTime => eventPeriod?.start;

  DateTime? get eventEndTime => eventPeriod?.end;

  Duration? get eventDuration => eventPeriod?.duration;
}
