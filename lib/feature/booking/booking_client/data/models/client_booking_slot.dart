enum ClientBookingSlotStatus {
  available,
  selected,
  myConflict,
  hostBusy,
}

class ClientBookingSlot {
  const ClientBookingSlot({
    required this.startsAt,
    required this.status,
    this.conflictLabel,
  });

  final DateTime startsAt;
  final ClientBookingSlotStatus status;
  final String? conflictLabel;

  String get timeLabel {
    return '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
  }

  bool get isSelectable => status == ClientBookingSlotStatus.available || status == ClientBookingSlotStatus.selected;
}
