// Локальные моки «Бронь» — без бэка. См. docs/business/venue-seating.md.

enum VenueMockLadder {
  /// A — только тарифы / билеты.
  tickets,

  /// B — места списком.
  seats,

  /// C — схема + места.
  plan,
}

enum VenueMockBookableState {
  free,
  held,
  taken,
}

class VenueMockVenue {
  const VenueMockVenue({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.ladder,
    required this.hasPlan,
  });

  final String id;
  final String name;
  final String subtitle;
  final VenueMockLadder ladder;
  final bool hasPlan;
}

class VenueMockTicket {
  const VenueMockTicket({
    required this.id,
    required this.title,
    required this.priceHint,
    required this.remaining,
  });

  final String id;
  final String title;
  final String priceHint;
  final int remaining;
}

class VenueMockSeat {
  const VenueMockSeat({
    required this.id,
    required this.label,
    required this.capacity,
    required this.state,
    this.priceHint,
  });

  final String id;
  final String label;
  final int capacity;
  final VenueMockBookableState state;
  final String? priceHint;
}

class VenueMockSession {
  const VenueMockSession({
    required this.id,
    required this.title,
    required this.whenLabel,
    required this.freeCount,
    required this.totalCount,
  });

  final String id;
  final String title;
  final String whenLabel;
  final int freeCount;
  final int totalCount;
}

enum VenueMockReservationStatus {
  requested,
  confirmed,
  declined,
  expired,
}

class VenueMockReservation {
  const VenueMockReservation({
    required this.id,
    required this.guestName,
    required this.placeLabel,
    required this.whenLabel,
    required this.guests,
    required this.comment,
    required this.status,
    required this.tab,
  });

  final String id;
  final String guestName;
  final String placeLabel;
  final String whenLabel;
  final int guests;
  final String comment;
  final VenueMockReservationStatus status;
  final VenueMockInboxTab tab;
}

enum VenueMockInboxTab {
  requests,
  confirmed,
  today,
  archive,
}

class VenueMockPlanNode {
  const VenueMockPlanNode({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.state,
    this.isDecor = false,
  });

  final String id;
  final String label;
  /// 0..1 доли от холста.
  final double left;
  final double top;
  final double width;
  final double height;
  final VenueMockBookableState state;
  final bool isDecor;
}

abstract final class VenueMockCatalog {
  static const venues = <VenueMockVenue>[
    VenueMockVenue(
      id: 'poetry',
      name: 'Вечер поэзии',
      subtitle: 'Уровень A · билеты без схемы',
      ladder: VenueMockLadder.tickets,
      hasPlan: false,
    ),
    VenueMockVenue(
      id: 'cafe',
      name: 'Кафе Clover',
      subtitle: 'Уровень C · столы на схеме',
      ladder: VenueMockLadder.plan,
      hasPlan: true,
    ),
    VenueMockVenue(
      id: 'cinema',
      name: 'Кино Star',
      subtitle: 'Уровень C · кресла + сеансы',
      ladder: VenueMockLadder.plan,
      hasPlan: true,
    ),
  ];

  static VenueMockVenue? venueById(String id) {
    for (final v in venues) {
      if (v.id == id) return v;
    }
    return null;
  }

  static List<VenueMockTicket> ticketsFor(String venueId) {
    return switch (venueId) {
      'poetry' => const [
        VenueMockTicket(id: 't1', title: 'Вход', priceHint: '2 000 ₸', remaining: 48),
        VenueMockTicket(id: 't2', title: 'VIP', priceHint: '5 000 ₸', remaining: 12),
      ],
      _ => const [
        VenueMockTicket(id: 't0', title: 'Общий вход', priceHint: '1 500 ₸', remaining: 20),
      ],
    };
  }

  static List<VenueMockSeat> seatsFor(String venueId) {
    return switch (venueId) {
      'cafe' => const [
        VenueMockSeat(id: 's1', label: 'Стол у окна', capacity: 2, state: VenueMockBookableState.free, priceHint: '—'),
        VenueMockSeat(id: 's2', label: 'Стол 2', capacity: 4, state: VenueMockBookableState.held, priceHint: '—'),
        VenueMockSeat(id: 's3', label: 'Стол 3', capacity: 4, state: VenueMockBookableState.free, priceHint: '—'),
        VenueMockSeat(id: 's4', label: 'Большой стол', capacity: 6, state: VenueMockBookableState.taken, priceHint: '—'),
        VenueMockSeat(id: 's5', label: 'Барная стойка', capacity: 2, state: VenueMockBookableState.free, priceHint: '—'),
      ],
      'cinema' => const [
        VenueMockSeat(id: 'a1', label: 'A1', capacity: 1, state: VenueMockBookableState.free, priceHint: '1 800 ₸'),
        VenueMockSeat(id: 'a2', label: 'A2', capacity: 1, state: VenueMockBookableState.taken, priceHint: '1 800 ₸'),
        VenueMockSeat(id: 'a3', label: 'A3', capacity: 1, state: VenueMockBookableState.free, priceHint: '1 800 ₸'),
        VenueMockSeat(id: 'b1', label: 'B1', capacity: 1, state: VenueMockBookableState.held, priceHint: '2 200 ₸'),
        VenueMockSeat(id: 'b2', label: 'B2', capacity: 1, state: VenueMockBookableState.free, priceHint: '2 200 ₸'),
        VenueMockSeat(id: 'b3', label: 'B3', capacity: 1, state: VenueMockBookableState.free, priceHint: '2 200 ₸'),
      ],
      _ => const [],
    };
  }

  static List<VenueMockSession> sessionsFor(String venueId) {
    return switch (venueId) {
      'poetry' => const [
        VenueMockSession(
          id: 'po1',
          title: 'Открытый микрофон',
          whenLabel: 'Сегодня · 20:00',
          freeCount: 60,
          totalCount: 80,
        ),
      ],
      'cafe' => const [
        VenueMockSession(
          id: 'cf1',
          title: 'Ужин',
          whenLabel: 'Сегодня · 19:00–21:00',
          freeCount: 3,
          totalCount: 5,
        ),
        VenueMockSession(
          id: 'cf2',
          title: 'Ужин',
          whenLabel: 'Завтра · 19:00–21:00',
          freeCount: 5,
          totalCount: 5,
        ),
      ],
      'cinema' => const [
        VenueMockSession(
          id: 'ci1',
          title: 'Фильм · Зал 1',
          whenLabel: 'Сегодня · 19:00',
          freeCount: 4,
          totalCount: 6,
        ),
        VenueMockSession(
          id: 'ci2',
          title: 'Фильм · Зал 1',
          whenLabel: 'Сегодня · 21:30',
          freeCount: 6,
          totalCount: 6,
        ),
      ],
      _ => const [],
    };
  }

  static List<VenueMockPlanNode> planFor(String venueId) {
    return switch (venueId) {
      'cafe' => const [
        VenueMockPlanNode(
          id: 'decor-bar',
          label: 'Бар',
          left: 0.08,
          top: 0.08,
          width: 0.84,
          height: 0.12,
          state: VenueMockBookableState.free,
          isDecor: true,
        ),
        VenueMockPlanNode(
          id: 's1',
          label: 'Окно',
          left: 0.08,
          top: 0.28,
          width: 0.28,
          height: 0.22,
          state: VenueMockBookableState.free,
        ),
        VenueMockPlanNode(
          id: 's2',
          label: '2',
          left: 0.42,
          top: 0.28,
          width: 0.22,
          height: 0.22,
          state: VenueMockBookableState.held,
        ),
        VenueMockPlanNode(
          id: 's3',
          label: '3',
          left: 0.70,
          top: 0.28,
          width: 0.22,
          height: 0.22,
          state: VenueMockBookableState.free,
        ),
        VenueMockPlanNode(
          id: 's4',
          label: 'Большой',
          left: 0.18,
          top: 0.58,
          width: 0.36,
          height: 0.28,
          state: VenueMockBookableState.taken,
        ),
        VenueMockPlanNode(
          id: 's5',
          label: 'Бар',
          left: 0.62,
          top: 0.62,
          width: 0.28,
          height: 0.20,
          state: VenueMockBookableState.free,
        ),
      ],
      'cinema' => const [
        VenueMockPlanNode(
          id: 'stage',
          label: 'Экран',
          left: 0.15,
          top: 0.06,
          width: 0.70,
          height: 0.10,
          state: VenueMockBookableState.free,
          isDecor: true,
        ),
        VenueMockPlanNode(
          id: 'a1',
          label: 'A1',
          left: 0.18,
          top: 0.28,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.free,
        ),
        VenueMockPlanNode(
          id: 'a2',
          label: 'A2',
          left: 0.41,
          top: 0.28,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.taken,
        ),
        VenueMockPlanNode(
          id: 'a3',
          label: 'A3',
          left: 0.64,
          top: 0.28,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.free,
        ),
        VenueMockPlanNode(
          id: 'b1',
          label: 'B1',
          left: 0.18,
          top: 0.50,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.held,
        ),
        VenueMockPlanNode(
          id: 'b2',
          label: 'B2',
          left: 0.41,
          top: 0.50,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.free,
        ),
        VenueMockPlanNode(
          id: 'b3',
          label: 'B3',
          left: 0.64,
          top: 0.50,
          width: 0.18,
          height: 0.14,
          state: VenueMockBookableState.free,
        ),
      ],
      _ => const [],
    };
  }

  static List<VenueMockReservation> reservationsFor(String venueId) {
    return switch (venueId) {
      'cafe' => const [
        VenueMockReservation(
          id: 'r1',
          guestName: 'Айгерим',
          placeLabel: 'Стол 2',
          whenLabel: 'Сегодня · 19:00',
          guests: 4,
          comment: 'Нужен стул для ребёнка',
          status: VenueMockReservationStatus.requested,
          tab: VenueMockInboxTab.requests,
        ),
        VenueMockReservation(
          id: 'r2',
          guestName: 'Данияр',
          placeLabel: 'Стол у окна',
          whenLabel: 'Завтра · 20:00',
          guests: 2,
          comment: '',
          status: VenueMockReservationStatus.confirmed,
          tab: VenueMockInboxTab.confirmed,
        ),
        VenueMockReservation(
          id: 'r3',
          guestName: 'Гость · walk-in',
          placeLabel: 'Большой стол',
          whenLabel: 'Сегодня · сейчас',
          guests: 5,
          comment: 'Админ отметил вручную',
          status: VenueMockReservationStatus.confirmed,
          tab: VenueMockInboxTab.today,
        ),
        VenueMockReservation(
          id: 'r4',
          guestName: 'Сабина',
          placeLabel: 'Стол 3',
          whenLabel: 'Вчера · 18:30',
          guests: 3,
          comment: 'TTL истек',
          status: VenueMockReservationStatus.expired,
          tab: VenueMockInboxTab.archive,
        ),
      ],
      'cinema' => const [
        VenueMockReservation(
          id: 'r5',
          guestName: 'Нурлан',
          placeLabel: 'B1 + B2',
          whenLabel: 'Сегодня · 19:00',
          guests: 2,
          comment: 'Ряд ближе к центру',
          status: VenueMockReservationStatus.requested,
          tab: VenueMockInboxTab.requests,
        ),
      ],
      'poetry' => const [
        VenueMockReservation(
          id: 'r6',
          guestName: 'Камила',
          placeLabel: 'VIP × 2',
          whenLabel: 'Сегодня · 20:00',
          guests: 2,
          comment: '',
          status: VenueMockReservationStatus.requested,
          tab: VenueMockInboxTab.requests,
        ),
      ],
      _ => const [],
    };
  }

  static String stateLabel(VenueMockBookableState state) => switch (state) {
    VenueMockBookableState.free => 'Свободно',
    VenueMockBookableState.held => 'На рассмотрении',
    VenueMockBookableState.taken => 'Занято',
  };

  static String statusLabel(VenueMockReservationStatus status) => switch (status) {
    VenueMockReservationStatus.requested => 'Запрос',
    VenueMockReservationStatus.confirmed => 'Подтверждено',
    VenueMockReservationStatus.declined => 'Отклонено',
    VenueMockReservationStatus.expired => 'Истекло',
  };

  static String tabLabel(VenueMockInboxTab tab) => switch (tab) {
    VenueMockInboxTab.requests => 'Запросы',
    VenueMockInboxTab.confirmed => 'Подтверждённые',
    VenueMockInboxTab.today => 'Сегодня',
    VenueMockInboxTab.archive => 'Архив',
  };
}
