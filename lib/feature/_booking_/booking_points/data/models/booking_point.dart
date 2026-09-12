/// Точка (место) хозяина записи — `booking_points`.
class BookingPoint {
  const BookingPoint({
    required this.id,
    required this.hostId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String hostId;
  final String name;
  final DateTime? createdAt;

  factory BookingPoint.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim() ?? '';
    final createdRaw = json['created_at']?.toString();
    return BookingPoint(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      name: rawName.isEmpty ? 'Точка' : rawName,
      createdAt: createdRaw == null || createdRaw.isEmpty ? null : DateTime.tryParse(createdRaw),
    );
  }
}
