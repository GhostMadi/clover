import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Включить обёртку [SupabaseLoggingHttpClient] в [Supabase.initialize].
/// По умолчанию только в debug-сборке.
bool get supabaseHttpLoggingEnabled => kDebugMode;

/// Глобальное логирование HTTP-запросов Supabase (PostgREST, Auth, Storage и т.д.).
///
/// Пишет метод, URL, статус ответа и длительность. Тело запроса/ответа не дублируется
/// (избегаем утечек и лишнего шума); внутренний логгер Supabase при `debug: true` дополняет картину.
class SupabaseLoggingHttpClient extends http.BaseClient {
  SupabaseLoggingHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sw = Stopwatch()..start();
    final uri = request.url;
    final line = '→ ${request.method} $uri';
    developer.log(line, name: 'SupabaseHTTP');
    try {
      final response = await _inner.send(request);
      final reason = response.reasonPhrase;
      developer.log(
        '← ${response.statusCode}${reason != null && reason.isNotEmpty ? ' $reason' : ''} '
        '${sw.elapsedMilliseconds}ms · ${request.method} $uri',
        name: 'SupabaseHTTP',
      );
      return response;
    } catch (e, st) {
      developer.log(
        '✗ ${sw.elapsedMilliseconds}ms · ${request.method} $uri · $e',
        name: 'SupabaseHTTP',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
