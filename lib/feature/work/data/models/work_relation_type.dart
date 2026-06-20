/// Intent профессиональной связи (`public.relations.relation_type`).
enum WorkRelationType {
  hire('hire'),
  join('join');

  const WorkRelationType(this.dbValue);

  final String dbValue;

  static WorkRelationType? fromDb(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    for (final item in WorkRelationType.values) {
      if (item.dbValue == v) return item;
    }
    return null;
  }

  String get actionSubtitle => switch (this) {
    WorkRelationType.hire => 'Хочет добавить вас как работника',
    WorkRelationType.join => 'Хочет присоединиться к вашей команде',
  };

  String get outgoingPendingSubtitle => switch (this) {
    WorkRelationType.hire => 'Приглашение на работу',
    WorkRelationType.join => 'Заявка на присоединение',
  };
}
