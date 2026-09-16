import 'package:characters/characters.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';

/// Normalize helpers for shared emoji wallpaper. Persistence = Supabase RPC.
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

  /// Legacy local keys — cleared on logout; no longer source of truth.
  Future<void> clearLegacy(String conversationKey) =>
      _storage.delete(key: storageKey(conversationKey));

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
