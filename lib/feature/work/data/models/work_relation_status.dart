/// Статус профессиональной связи (`public.relations.status`).
enum WorkRelationStatus {
  pending('pending'),
  active('active'),
  rejected('rejected'),
  terminated('terminated');

  const WorkRelationStatus(this.dbValue);

  final String dbValue;

  static WorkRelationStatus? fromDb(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    for (final item in WorkRelationStatus.values) {
      if (item.dbValue == v) return item;
    }
    return null;
  }

  String get label => switch (this) {
    WorkRelationStatus.pending => 'Ожидает',
    WorkRelationStatus.active => 'Принято',
    WorkRelationStatus.rejected => 'Отклонено',
    WorkRelationStatus.terminated => 'Завершено',
  };

  /// Связь уже есть — новую заявку этому peer отправить нельзя.
  bool get blocksNewRequest => switch (this) {
    WorkRelationStatus.pending || WorkRelationStatus.active => true,
    WorkRelationStatus.rejected || WorkRelationStatus.terminated => false,
  };
}
