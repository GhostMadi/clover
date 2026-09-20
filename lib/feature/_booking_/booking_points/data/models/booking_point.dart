/// Точка (место) хозяина записи — `booking_points`.
class BookingPoint {
  const BookingPoint({
    required this.id,
    required this.hostId,
    required this.name,
    required this.createdAt,
    this.groupConversationId,
  });

  final String id;
  final String hostId;
  final String name;
  final DateTime? createdAt;
  final String? groupConversationId;

  factory BookingPoint.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim() ?? '';
    final createdRaw = json['created_at']?.toString();
    final chat = json['group_conversation_id']?.toString().trim();
    return BookingPoint(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      name: rawName.isEmpty ? 'Точка' : rawName,
      createdAt: createdRaw == null || createdRaw.isEmpty ? null : DateTime.tryParse(createdRaw),
      groupConversationId: (chat == null || chat.isEmpty) ? null : chat,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'host_id': hostId,
        'name': name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (groupConversationId != null) 'group_conversation_id': groupConversationId,
      };

  BookingPoint copyWith({
    String? id,
    String? hostId,
    String? name,
    DateTime? createdAt,
    String? groupConversationId,
  }) {
    return BookingPoint(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      groupConversationId: groupConversationId ?? this.groupConversationId,
    );
  }
}
