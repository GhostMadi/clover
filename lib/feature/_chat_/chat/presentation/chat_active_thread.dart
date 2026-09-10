import 'package:injectable/injectable.dart';

/// Currently open DM thread — suppress in-app chat banner for this conversation.
@lazySingleton
class ChatActiveThread {
  String? _conversationId;

  String? get conversationId => _conversationId;

  void enter(String conversationId) {
    final id = conversationId.trim();
    _conversationId = id.isEmpty ? null : id;
  }

  void leave([String? conversationId]) {
    if (conversationId == null || conversationId.trim().isEmpty) {
      _conversationId = null;
      return;
    }
    if (_conversationId == conversationId.trim()) {
      _conversationId = null;
    }
  }

  bool isOpen(String conversationId) {
    final id = conversationId.trim();
    return id.isNotEmpty && _conversationId == id;
  }
}
