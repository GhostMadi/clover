import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';

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

  bool get isSelectable => status.isSelectable;

  ClientBookingSlot copyWith({
    DateTime? startsAt,
    ClientBookingSlotStatus? status,
    String? conflictLabel,
  }) {
    return ClientBookingSlot(
      startsAt: startsAt ?? this.startsAt,
      status: status ?? this.status,
      conflictLabel: conflictLabel ?? this.conflictLabel,
    );
  }
}
