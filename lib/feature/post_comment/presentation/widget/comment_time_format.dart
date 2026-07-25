abstract final class CommentTimeFormat {
  CommentTimeFormat._();

  static String format(DateTime createdAt) {
    final local = createdAt.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inHours < 1) return '${diff.inMinutes} мин.';
    if (diff.inDays < 1) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} д.';
    if (local.year == DateTime.now().year) {
      return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
