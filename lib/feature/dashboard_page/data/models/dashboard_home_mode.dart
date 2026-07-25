enum DashboardHomeMode {
  events,
  map;

  static DashboardHomeMode fromStorage(String? raw) {
    return switch (raw?.trim()) {
      'map' => DashboardHomeMode.map,
      _ => DashboardHomeMode.events,
    };
  }

  String get storageValue => switch (this) {
    DashboardHomeMode.events => 'events',
    DashboardHomeMode.map => 'map',
  };
}
