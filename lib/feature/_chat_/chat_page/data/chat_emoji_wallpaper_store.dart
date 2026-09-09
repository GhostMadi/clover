import 'package:characters/characters.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';

/// Локальный фон чата (смайлики). См. docs/business/chat-emoji-wallpaper.md
@lazySingleton
class ChatEmojiWallpaperStore {
  ChatEmojiWallpaperStore(this._storage);

  final IAppStorage _storage;

  static const maxEmojis = 8;
  static const _prefix = 'chat_wallpaper_';

  static String storageKey(String conversationKey) {
    final id = conversationKey.trim();
    return '$_prefix${id.isEmpty ? 'unknown' : id}';
  }

  Future<List<String>> read(String conversationKey) async {
    final raw = await _storage.read<List<dynamic>>(key: storageKey(conversationKey));
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ].take(maxEmojis).toList(growable: false);
  }

  Future<void> write(String conversationKey, List<String> emojis) async {
    final cleaned = normalizeEmojis(emojis);
    final key = storageKey(conversationKey);
    if (cleaned.isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write<List<dynamic>>(key: key, value: cleaned);
  }

  Future<void> clear(String conversationKey) => _storage.delete(key: storageKey(conversationKey));

  /// Уникальные grapheme-кластеры из ввода пользователя.
  static List<String> normalizeEmojis(Iterable<String> raw, {int max = maxEmojis}) {
    final out = <String>[];
    for (final piece in raw) {
      for (final ch in piece.characters) {
        if (ch.trim().isEmpty) continue;
        if (out.contains(ch)) continue;
        out.add(ch);
        if (out.length >= max) return List<String>.unmodifiable(out);
      }
    }
    return List<String>.unmodifiable(out);
  }

  static List<String> parseInput(String input) => normalizeEmojis([input]);
}
