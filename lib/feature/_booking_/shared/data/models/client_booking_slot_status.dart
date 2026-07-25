/// Статус слота из `get_booking_availability` (+ `selected` только на клиенте).
enum ClientBookingSlotStatus {
  available('available'),
  selected('selected'),
  myConflict('my_conflict'),
  hostBusy('host_busy');

  const ClientBookingSlotStatus(this.apiValue);

  final String apiValue;

  static ClientBookingSlotStatus? fromApi(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    for (final item in ClientBookingSlotStatus.values) {
      if (item.apiValue == v) return item;
    }
    return null;
  }

  static ClientBookingSlotStatus fromApiOrAvailable(String? raw) =>
      fromApi(raw) ?? ClientBookingSlotStatus.available;

  bool get isSelectable =>
      this == ClientBookingSlotStatus.available || this == ClientBookingSlotStatus.selected;
}
