/// EN keys for `content_reports.reason_code` (бэк); подписи — только на клиенте.
enum ContentReportReason {
  objectionableContent,
  abusiveUser,
  spam,
  harassment,
  other;

  String get apiKey => switch (this) {
        ContentReportReason.objectionableContent => 'objectionable_content',
        ContentReportReason.abusiveUser => 'abusive_user',
        ContentReportReason.spam => 'spam',
        ContentReportReason.harassment => 'harassment',
        ContentReportReason.other => 'other',
      };

  String get labelRu => switch (this) {
        ContentReportReason.objectionableContent => 'Неприемлемый контент',
        ContentReportReason.abusiveUser => 'Оскорбительное поведение',
        ContentReportReason.spam => 'Спам',
        ContentReportReason.harassment => 'Травля / угрозы',
        ContentReportReason.other => 'Другое',
      };
}
