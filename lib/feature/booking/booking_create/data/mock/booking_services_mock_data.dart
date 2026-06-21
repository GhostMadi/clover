import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';

/// Временные данные для вёрстки списка услуг.
abstract final class BookingServicesMockData {
  static const executors = [
    BookingServiceExecutor(
      id: 'exec-1',
      displayName: 'Алия К.',
      username: 'aliya_k',
    ),
    BookingServiceExecutor(
      id: 'exec-2',
      displayName: 'Марат Т.',
      username: 'marat_t',
    ),
    BookingServiceExecutor(
      id: 'exec-3',
      displayName: 'Diana S.',
      username: 'diana_s',
    ),
  ];

  static const items = [
    BookingService(
      id: '1',
      title: 'Стрижка мужская',
      durationMinutes: 45,
      emojiText: '💈',
      price: 3500,
      maxParticipants: 1,
      bufferAfterMinutes: 15,
      description: 'Модельная стрижка, укладка',
      executorIds: ['exec-1'],
      isActive: true,
    ),
    BookingService(
      id: '2',
      title: 'Консультация',
      durationMinutes: 30,
      emojiText: '💬',
      price: 0,
      maxParticipants: 1,
      bufferAfterMinutes: 0,
      isActive: true,
    ),
    BookingService(
      id: '3',
      title: 'Маникюр',
      durationMinutes: 60,
      emojiText: '💅',
      price: 5000,
      maxParticipants: 2,
      bufferAfterMinutes: 10,
      description: 'Покрытие гель-лаком',
      executorIds: ['exec-3'],
      isActive: false,
    ),
  ];

  static BookingServiceExecutor? executorById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final executor in executors) {
      if (executor.id == id) return executor;
    }
    return null;
  }
}
