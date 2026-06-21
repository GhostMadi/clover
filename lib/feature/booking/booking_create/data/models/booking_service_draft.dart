import 'package:clover/feature/booking/booking_create/data/models/booking_executor_pick.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';

class BookingServiceDraft {
  const BookingServiceDraft({
    this.title = '',
    this.durationMinutes = 30,
    this.emojiText = '',
    this.price = 0,
    this.maxParticipants = 1,
    this.bufferAfterMinutes = 0,
    this.description = '',
    this.executors = const [],
    this.isActive = true,
  });

  final String title;
  final int durationMinutes;
  final String emojiText;
  final double price;
  final int maxParticipants;
  final int bufferAfterMinutes;
  final String description;
  final List<BookingExecutorPick> executors;
  final bool isActive;

  bool get hasEmoji => emojiText.trim().isNotEmpty;

  bool get hasExecutors => executors.isNotEmpty;

  String? get defaultExecutorStaffId {
    for (final pick in executors) {
      final id = pick.staffId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  bool get isValid {
    if (title.trim().isEmpty) return false;
    if (!hasEmoji) return false;
    if (durationMinutes <= 0) return false;
    if (price < 0) return false;
    if (maxParticipants < 1) return false;
    if (bufferAfterMinutes < 0) return false;
    if (!hasExecutors) return false;
    return true;
  }

  factory BookingServiceDraft.fromService(BookingService service) {
    return BookingServiceDraft(
      title: service.title,
      durationMinutes: service.durationMinutes,
      emojiText: service.emojiText,
      price: service.price,
      maxParticipants: service.maxParticipants,
      bufferAfterMinutes: service.bufferAfterMinutes,
      description: service.description ?? '',
      executors: [
        for (final id in service.executorIds)
          BookingExecutorPick(
            staffId: id,
            displayName: '',
            username: '',
          ),
      ],
      isActive: service.isActive,
    );
  }

  BookingServiceDraft copyWith({
    String? title,
    int? durationMinutes,
    String? emojiText,
    double? price,
    int? maxParticipants,
    int? bufferAfterMinutes,
    String? description,
    List<BookingExecutorPick>? executors,
    bool? isActive,
  }) {
    return BookingServiceDraft(
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      emojiText: emojiText ?? this.emojiText,
      price: price ?? this.price,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      bufferAfterMinutes: bufferAfterMinutes ?? this.bufferAfterMinutes,
      description: description ?? this.description,
      executors: executors ?? this.executors,
      isActive: isActive ?? this.isActive,
    );
  }
}
