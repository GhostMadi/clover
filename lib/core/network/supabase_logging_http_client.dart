import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Включить обёртку [SupabaseLoggingHttpClient] в [Supabase.initialize].
/// По умолчанию только в debug-сборке.
bool get supabaseHttpLoggingEnabled => kDebugMode;

const _logName = 'SupabaseHTTP';
const _maxBodyLogChars = 6000;

/// HTTP-лог Supabase: короткая строка запроса + тело req/res как JSON.
class SupabaseLoggingHttpClient extends http.BaseClient {
  SupabaseLoggingHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sw = Stopwatch()..start();
    final summary = _requestSummary(request);

    final prepared = await _prepareRequest(request);
    final reqBody = _bodyText(prepared);

    _log('→ ${prepared.method} $summary');
    _logBody('req', reqBody);

    try {
      final response = await _inner.send(prepared);
      final bytes = await response.stream.toBytes();
      sw.stop();

      final resBody = _decodeBytes(bytes);
      _log('← ${response.statusCode} ${sw.elapsedMilliseconds}ms · ${prepared.method} $summary');
      _logBody('res', resBody);

      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
      );
    } catch (e, st) {
      sw.stop();
      developer.log(
        '✗ ${sw.elapsedMilliseconds}ms · ${prepared.method} $summary · $e',
        name: _logName,
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

  static void _log(String message) {
    developer.log(message, name: _logName);
  }

  static void _logBody(String label, String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    final formatted = _formatBody(raw);
    _log('  $label:');
    for (final line in formatted.split('\n')) {
      _log('    $line');
    }
  }

  /// Короткий путь: `profiles`, `rpc/list_user_feed_enriched_cursor`.
  static String _requestSummary(http.BaseRequest request) {
    final uri = request.url;
    final path = _shortPath(uri);
    final query = _shortQuery(uri);
    if (query == null || query.isEmpty) return path;
    return '$path?$query';
  }

  static String _shortPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 3 && segments[0] == 'rest' && segments[1] == 'v1') {
      if (segments[2] == 'rpc' && segments.length > 3) {
        return 'rpc/${segments[3]}';
      }
      return segments[2];
    }
    if (segments.isEmpty) return uri.path.isEmpty ? uri.host : uri.path;
    if (segments.length >= 2) {
      return segments.sublist(segments.length - 2).join('/');
    }
    return segments.last;
  }

  static String? _shortQuery(Uri uri) {
    if (uri.queryParameters.isEmpty) return null;

    final parts = <String>[];
    for (final entry in uri.queryParameters.entries) {
      if (parts.length >= 5) {
        parts.add('…');
        break;
      }
      parts.add('${entry.key}=${_truncate(entry.value, 48)}');
    }
    return parts.join('&');
  }

  static Future<http.BaseRequest> _prepareRequest(http.BaseRequest request) async {
    if (request is http.Request) return request;

    if (request is http.StreamedRequest) {
      final bytes = await request.finalize().toBytes();
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = bytes
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }

    return request;
  }

  static String? _bodyText(http.BaseRequest request) {
    if (request is! http.Request) return null;
    if (request.body.isNotEmpty) return request.body;
    if (request.bodyBytes.isNotEmpty) {
      return _decodeBytes(request.bodyBytes);
    }
    return null;
  }

  static String _decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _formatBody(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    try {
      final decoded = jsonDecode(trimmed);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return _truncate(pretty, _maxBodyLogChars);
    } catch (_) {
      return _truncate(trimmed, _maxBodyLogChars);
    }
  }

  static String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}… (${value.length} chars)';
  }
}
