enum EventsContentKind {
  eventsOnly,
  all;

  String get label => switch (this) {
        EventsContentKind.eventsOnly => 'Ивенты',
        EventsContentKind.all => 'Все',
      };
}
