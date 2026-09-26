import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_horizon_kind.dart';
import 'package:flutter/foundation.dart';

/// Mock: схема точки Записи + bind emoji → услуга (+ мастер).
/// Ценники только на emoji. Бэка нет.
/// docs/business/space-plan-emoji-pricing.md
abstract final class BookingSpacePlanBindMock {
  static const bool enabled = true;

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static void _bump() => revision.value++;

  /// Демо-схемы (как в Ресурсах на сайте / JSON).
  static const plans = <({String id, String title, bool published})>[
    (id: 'sp_demo_cafe', title: 'Зал кафе (демо)', published: true),
    (id: 'sp_demo_cinema', title: 'Кинозал (демо)', published: false),
    (id: 'sp_emoji_chaos', title: '🌈 Emoji Carnival', published: true),
  ];

  static const mockServices = <({String id, String title, int priceKzt})>[
    (id: 'svc_cut', title: 'Стрижка', priceKzt: 5000),
    (id: 'svc_color', title: 'Окрашивание', priceKzt: 18000),
    (id: 'svc_manicure', title: 'Маникюр', priceKzt: 8000),
  ];

  static const mockStaff = <({String id, String name, List<String> serviceIds})>[
    (id: 'st_aigerim', name: 'Айгерим', serviceIds: ['svc_cut', 'svc_color']),
    (id: 'st_daniyar', name: 'Данияр', serviceIds: ['svc_cut']),
    (id: 'st_sabina', name: 'Сабина', serviceIds: ['svc_manicure', 'svc_color']),
  ];

  /// Демо-каталог барбершопа, если у хозяина ещё нет услуг/мастеров.
  static List<BookingServiceWithStaff> demoGuestCatalog() {
    final cut = BookingService(
      id: 'svc_cut',
      title: 'Стрижка',
      durationMinutes: 45,
      emojiText: '✂️',
      price: 5000,
      maxParticipants: 1,
      bufferAfterMinutes: 10,
    );
    final color = BookingService(
      id: 'svc_color',
      title: 'Окрашивание',
      durationMinutes: 90,
      emojiText: '👑',
      price: 18000,
      maxParticipants: 1,
      bufferAfterMinutes: 15,
    );
    final wash = BookingService(
      id: 'svc_manicure',
      title: 'Мытьё + укладка',
      durationMinutes: 30,
      emojiText: '🚿',
      price: 8000,
      maxParticipants: 1,
      bufferAfterMinutes: 5,
    );
    BookingServiceExecutor exec(String id, String name) => BookingServiceExecutor(
          id: id,
          displayName: name,
          username: name.toLowerCase(),
        );
    return [
      BookingServiceWithStaff(
        service: cut,
        staff: [exec('st_aigerim', 'Айгерим'), exec('st_daniyar', 'Данияр')],
      ),
      BookingServiceWithStaff(
        service: color,
        staff: [exec('st_aigerim', 'Айгерим'), exec('st_sabina', 'Сабина')],
      ),
      BookingServiceWithStaff(
        service: wash,
        staff: [exec('st_sabina', 'Сабина')],
      ),
    ];
  }

  /// Для гостевого mock: всегда есть услуги + хотя бы один мастер.
  static List<BookingServiceWithStaff> enrichCatalogForGuest(
    List<BookingServiceWithStaff> catalog,
  ) {
    if (catalog.isEmpty) return demoGuestCatalog();
    return [
      for (final c in catalog)
        if (c.staff.isNotEmpty)
          c
        else
          BookingServiceWithStaff(
            service: c.service,
            staff: [
              for (var i = 0; i < mockStaff.length; i++)
                BookingServiceExecutor(
                  id: 'mock_staff_${c.service.id}_$i',
                  displayName: mockStaff[i].name,
                  username: mockStaff[i].name.toLowerCase(),
                ),
            ],
          ),
    ];
  }

  /// Расписание на 21 день вперёд (выбор даты в mock).
  static BookingScheduleSettings demoGuestSchedule() {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return BookingScheduleSettings(
      restWeekdays: const {},
      horizonKind: BookingHorizonKind.daysAhead,
      maxBookingDaysAhead: 21,
      maxBookingUntilDate: base.add(const Duration(days: 21)),
      workStartHour: 10,
      workStartMinute: 0,
      workEndHour: 20,
      workEndMinute: 0,
      executorAbsences: const [],
      clientCancelHoursBefore: 0,
      autoCloseHoursAfterVisit: 0,
    );
  }

  /// Логический размер холста (как viewBox JSON-схемы).
  static const double canvasWidth = 400;
  static const double canvasHeight = 480;

  /// Фон схемы как в JSON (не из темы приложения).
  static const Map<String, int> canvasBackgroundArgb = {
    'sp_demo_cafe': 0xFFE8F5E9,
    'sp_demo_cinema': 0xFF1A1D1E,
    'sp_emoji_chaos': 0xFF1A1028,
  };

  /// Заливка декора как в редакторе (не theme).
  static const Map<String, int> decorFillArgb = {
    'sp_demo_cafe': 0xFFF7F7F8,
    'sp_demo_cinema': 0xFF2A2E30,
    'sp_emoji_chaos': 0xFF2A1848,
  };

  static const Map<String, int> decorStrokeArgb = {
    'sp_demo_cafe': 0xFFB54B45,
    'sp_demo_cinema': 0xFFD4C4B0,
    'sp_emoji_chaos': 0xFF7C5CBF,
  };

  /// Emoji на демо-схемах: координаты ≈ JSON layout для мобильного превью.
  static const Map<String, List<BookingPlanEmojiSpot>> emojisByPlan = {
    'sp_demo_cafe': [
      BookingPlanEmojiSpot('e_seat_1', '💺', '1 этаж', 48, 160, 44, 'g_seats'),
      BookingPlanEmojiSpot('e_seat_2', '💺', '1 этаж', 108, 160, 44, 'g_seats'),
      BookingPlanEmojiSpot('e_seat_3', '💺', '1 этаж', 168, 160, 44, 'g_seats'),
      BookingPlanEmojiSpot('e_seat_4', '💺', '1 этаж', 228, 160, 44, 'g_seats'),
      BookingPlanEmojiSpot('e_cut_1', '✂️', '1 этаж', 80, 280, 48, 'g_cut'),
      BookingPlanEmojiSpot('e_cut_2', '✂️', '1 этаж', 150, 280, 48, 'g_cut'),
      BookingPlanEmojiSpot('e_vip', '👑', '1 этаж', 280, 250, 52, null),
    ],
    'sp_demo_cinema': [
      BookingPlanEmojiSpot('e_row_a1', '🎬', 'зал', 60, 120, 44, 'g_row'),
      BookingPlanEmojiSpot('e_row_a2', '🎬', 'зал', 130, 120, 44, 'g_row'),
      BookingPlanEmojiSpot('e_row_a3', '🎬', 'зал', 200, 120, 44, 'g_row'),
      BookingPlanEmojiSpot('e_pop_1', '🍿', 'зал', 70, 280, 48, 'g_pop'),
      BookingPlanEmojiSpot('e_pop_2', '🍿', 'зал', 140, 280, 48, 'g_pop'),
    ],
    'sp_emoji_chaos': [
      BookingPlanEmojiSpot('n_dj_emoji', '🎧', 'Carnival', 40, 60, 56, null),
      BookingPlanEmojiSpot('n_food_1', '🍕', 'Carnival', 130, 180, 48, 'g_food'),
      BookingPlanEmojiSpot('n_food_2', '🍕', 'Carnival', 190, 200, 48, 'g_food'),
      BookingPlanEmojiSpot('n_food_3', '🍕', 'Carnival', 160, 250, 48, 'g_food'),
      BookingPlanEmojiSpot('n_pa1', '👽', 'Carnival', 300, 90, 52, null),
      BookingPlanEmojiSpot('n_vip1', '👑', 'Carnival', 280, 300, 50, 'g_vip'),
      BookingPlanEmojiSpot('n_vip2', '👑', 'Carnival', 340, 320, 50, 'g_vip'),
      BookingPlanEmojiSpot('n2_a', '🧑‍🚀', 'Cosmic', 60, 360, 56, null),
    ],
  };

  /// Декор зала (не кликается) — имитация фигур из JSON.
  static const Map<String, List<BookingPlanDecor>> decorByPlan = {
    'sp_demo_cafe': [
      BookingPlanDecor(28, 40, 344, 400, 24),
      BookingPlanDecor(48, 70, 200, 56, 14),
      BookingPlanDecor(260, 200, 100, 120, 18),
    ],
    'sp_demo_cinema': [
      BookingPlanDecor(24, 36, 352, 400, 20),
      BookingPlanDecor(70, 70, 260, 40, 12),
    ],
    'sp_emoji_chaos': [
      BookingPlanDecor(20, 28, 360, 420, 28),
      BookingPlanDecor(100, 140, 180, 160, 40),
      BookingPlanDecor(250, 260, 120, 100, 22),
    ],
  };

  static final Map<String, _PointBind> _byPoint = {};

  static _PointBind _state(String pointId) =>
      _byPoint.putIfAbsent(pointId, () => _PointBind());

  /// Ключ витрины гостя (чужой профиль → Запись).
  static String guestShowcaseKey(String hostId) => 'guest_showcase_$hostId';

  /// Подготовить демо-схему барбершопа для гостевого просмотра.
  static void ensureGuestShowcase(String hostId) {
    final key = guestShowcaseKey(hostId);
    final s = _state(key);
    s.spacePlanId = 'sp_demo_barbershop';
    _bump();
  }

  /// Ценники на emoji из JSON (legacy mock ids — только если каталога ещё нет).
  static void seedGuestBindsFromCafeEmojis(
    String hostId,
    List<({String nodeId, String emoji})> spots,
  ) {
    seedGuestBindsFromCatalog(
      hostId: hostId,
      spots: spots,
      services: [
        for (final s in mockServices)
          (
            id: s.id,
            title: s.title,
            priceKzt: s.priceKzt,
            emoji: switch (s.id) {
              'svc_cut' => '✂️',
              'svc_color' => '👑',
              'svc_manicure' => '🚿',
              _ => '💺',
            },
            staff: [
              for (final st in mockStaff)
                if (st.serviceIds.contains(s.id)) (id: st.id, name: st.name),
            ],
          ),
      ],
    );
  }

  /// Привязка мест схемы к **реальным** услугам/мастерам хозяина (каталог записи).
  static void seedGuestBindsFromCatalog({
    required String hostId,
    required List<({String nodeId, String emoji})> spots,
    required List<
        ({
          String id,
          String title,
          int priceKzt,
          String emoji,
          List<({String id, String name})> staff,
        })> services,
  }) {
    final key = guestShowcaseKey(hostId);
    final s = _state(key);
    s.spacePlanId = 'sp_demo_barbershop';
    s.binds.clear();
    if (services.isEmpty || spots.isEmpty) {
      _bump();
      return;
    }

    ({String id, String title, int priceKzt, String emoji, List<({String id, String name})> staff}) pickFor(
      String emoji,
      int index,
    ) {
      final byEmoji = services.where((svc) => svc.emoji == emoji).toList();
      if (byEmoji.isNotEmpty) return byEmoji[index % byEmoji.length];
      // Кресло / ножницы → первая «стрижка»-подобная или любая по кругу.
      if (emoji == '💺' || emoji == '✂️') {
        final cut = services.where((svc) {
          final t = svc.title.toLowerCase();
          return t.contains('стриж') || t.contains('cut') || svc.emoji == '✂️' || svc.emoji == '💇';
        }).toList();
        if (cut.isNotEmpty) return cut[index % cut.length];
      }
      if (emoji == '👑') {
        final vip = services.where((svc) {
          final t = svc.title.toLowerCase();
          return t.contains('vip') || t.contains('окраш') || t.contains('color') || svc.emoji == '👑';
        }).toList();
        if (vip.isNotEmpty) return vip[index % vip.length];
      }
      if (emoji == '🚿') {
        final wash = services.where((svc) {
          final t = svc.title.toLowerCase();
          return t.contains('мыт') || t.contains('wash') || t.contains('уклад');
        }).toList();
        if (wash.isNotEmpty) return wash[index % wash.length];
      }
      return services[index % services.length];
    }

    for (var i = 0; i < spots.length; i++) {
      final spot = spots[i];
      final svc = pickFor(spot.emoji, i);
      final staffList = svc.staff;
      final staff = staffList.isEmpty
          ? (
              id: mockStaff[i % mockStaff.length].id,
              name: mockStaff[i % mockStaff.length].name,
            )
          : staffList[i % staffList.length];
      s.binds[spot.nodeId] = BookingEmojiBind(
        nodeId: spot.nodeId,
        emoji: spot.emoji,
        serviceId: svc.id,
        serviceTitle: svc.title,
        priceKzt: svc.priceKzt,
        staffId: staff.id,
        staffName: staff.name,
      );
    }
    _bump();
  }

  static String? spacePlanId(String pointId) => _state(pointId).spacePlanId;

  static List<BookingEmojiBind> binds(String pointId) =>
      List.unmodifiable(_state(pointId).binds.values);

  static BookingEmojiBind? bindFor(String pointId, String nodeId) =>
      _state(pointId).binds[nodeId];

  static void setSpacePlan(String pointId, String? planId) {
    final s = _state(pointId);
    if (s.spacePlanId != planId) {
      s.spacePlanId = planId;
      s.binds.clear();
    }
    _bump();
  }

  static void upsertBind({
    required String pointId,
    required String nodeId,
    required String emoji,
    required String serviceId,
    required String serviceTitle,
    required int priceKzt,
    String? staffId,
    String? staffName,
  }) {
    _state(pointId).binds[nodeId] = BookingEmojiBind(
      nodeId: nodeId,
      emoji: emoji,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      priceKzt: priceKzt,
      staffId: staffId,
      staffName: staffName,
    );
    _bump();
  }

  static void upsertBindsBulk({
    required String pointId,
    required List<String> nodeIds,
    required String emoji,
    required String serviceId,
    required String serviceTitle,
    required int priceKzt,
    String? staffId,
    String? staffName,
  }) {
    for (final id in nodeIds) {
      _state(pointId).binds[id] = BookingEmojiBind(
        nodeId: id,
        emoji: emoji,
        serviceId: serviceId,
        serviceTitle: serviceTitle,
        priceKzt: priceKzt,
        staffId: staffId,
        staffName: staffName,
      );
    }
    _bump();
  }

  static void clearBinds(String pointId, List<String> nodeIds) {
    for (final id in nodeIds) {
      _state(pointId).binds.remove(id);
    }
    _bump();
  }

  static void clearBind(String pointId, String nodeId) {
    clearBinds(pointId, [nodeId]);
  }

  static List<BookingPlanEmojiSpot> emojisForPoint(String pointId) {
    final id = spacePlanId(pointId);
    if (id == null) return const [];
    return emojisByPlan[id] ?? const [];
  }

  static List<BookingPlanDecor> decorForPoint(String pointId) {
    final id = spacePlanId(pointId);
    if (id == null) return const [];
    return decorByPlan[id] ?? const [];
  }

  static int canvasBackgroundArgbForPoint(String pointId) {
    final id = spacePlanId(pointId);
    return canvasBackgroundArgb[id] ?? 0xFFF7F7F8;
  }

  static int decorFillArgbForPoint(String pointId) {
    final id = spacePlanId(pointId);
    return decorFillArgb[id] ?? 0xFFF7F7F8;
  }

  static int decorStrokeArgbForPoint(String pointId) {
    final id = spacePlanId(pointId);
    return decorStrokeArgb[id] ?? 0xFFB54B45;
  }

  static List<({String glyph, List<BookingPlanEmojiSpot> spots})> groupsForPoint(
    String pointId,
  ) {
    final spots = emojisForPoint(pointId);
    final map = <String, List<BookingPlanEmojiSpot>>{};
    for (final s in spots) {
      map.putIfAbsent(s.emoji, () => []).add(s);
    }
    return [for (final e in map.entries) (glyph: e.key, spots: e.value)];
  }
}

@immutable
final class BookingPlanEmojiSpot {
  const BookingPlanEmojiSpot(
    this.nodeId,
    this.emoji,
    this.floor,
    this.x,
    this.y,
    this.size, [
    this.groupId,
  ]);

  final String nodeId;
  final String emoji;
  final String floor;
  final double x;
  final double y;
  final double size;
  final String? groupId;
}

@immutable
final class BookingPlanDecor {
  const BookingPlanDecor(this.x, this.y, this.w, this.h, this.radius);

  final double x;
  final double y;
  final double w;
  final double h;
  final double radius;
}

final class BookingEmojiBind {
  const BookingEmojiBind({
    required this.nodeId,
    required this.emoji,
    required this.serviceId,
    required this.serviceTitle,
    required this.priceKzt,
    this.staffId,
    this.staffName,
  });

  final String nodeId;
  final String emoji;
  final String serviceId;
  final String serviceTitle;
  final int priceKzt;
  final String? staffId;
  final String? staffName;
}

class _PointBind {
  String? spacePlanId;
  final Map<String, BookingEmojiBind> binds = {};
}
