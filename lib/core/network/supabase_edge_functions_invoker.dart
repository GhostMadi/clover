import 'dart:convert';
import 'dart:developer' as developer;

import 'package:clover/core/auth/errors/auth_error_mapper.dart';
import 'package:clover/core/config/supabase.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Обёртка над [SupabaseClient.functions.invoke]: к каждому вызову добавляет
/// `Authorization: Bearer <access_token>` (с обновлением сессии при истечении).
///
/// Новые Edge Functions вызывайте только через этот класс, чтобы JWT не терялся
/// из‑за `putIfAbsent` в [AuthHttpClient].
@lazySingleton
class SupabaseEdgeFunctionsInvoker {
  SupabaseEdgeFunctionsInvoker(this._client);

  final SupabaseClient _client;

  static const _refreshSkewSeconds = 120;

  /// JWT для заголовка `Authorization` (при необходимости обновляет сессию).
  Future<String> requireUserAccessToken() async {
    var session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('Требуется вход в аккаунт');
    }

    final expiresAt = session.expiresAt;
    final needsRefresh =
        session.isExpired ||
        (expiresAt != null &&
            DateTime.now().toUtc().isAfter(
              DateTime.fromMillisecondsSinceEpoch(
                expiresAt * 1000,
                isUtc: true,
              ).subtract(const Duration(seconds: _refreshSkewSeconds)),
            ));

    if (needsRefresh) {
      try {
        final refreshed = await _client.auth.refreshSession();
        session = refreshed.session ?? _client.auth.currentSession;
      } on AuthException catch (error) {
        if (AuthErrorMapper.isInvalidRefreshToken(error)) {
          try {
            await _client.auth.signOut(scope: SignOutScope.local);
          } catch (_) {}
        }
        throw StateError('Сессия истекла. Войдите снова.');
      }
    }

    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Не удалось получить токен авторизации');
    }
    if (kDebugMode) {
      final parts = token.split('.');
      if (parts.length >= 2) {
        try {
          final payloadB64 = parts[1];
          final normalized = base64.normalize(payloadB64);
          final payloadJson = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(payloadJson);
          if (payload is Map) {
            developer.log(
              'JWT payload: iss=${payload['iss']} ref=${payload['ref']} exp=${payload['exp']}',
              name: 'EdgeFn',
            );
          }
        } catch (_) {
          // ignore
        }
      }
    }
    return token;
  }

  /// Вызов функции с JWT пользователя. Заголовок [Authorization] выставляется
  /// последним и перекрывает одноимённый ключ из [headers], если был передан.
  ///
  /// Для **публичных** функций (без пользовательской сессии) передайте
  /// [withUserAuthorization]: false.
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Iterable<http.MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
    String? region,
    bool withUserAuthorization = true,
  }) async {
    final sw = Stopwatch()..start();
    if (method != HttpMethod.post) {
      throw UnimplementedError('Only POST is supported by this invoker right now');
    }

    final merged = <String, String>{...?headers};
    if (withUserAuthorization) {
      final token = await requireUserAccessToken();
      merged['Authorization'] = 'Bearer $token';
    }

    // Bypass SupabaseClient.functions.invoke to avoid Authorization header being dropped/overwritten.
    // IMPORTANT: `_client.rest.url` points to PostgREST (`.../rest/v1`), but Edge Functions live at `.../functions/v1`.
    final url = Uri.parse('${SupabaseConfig.url}/functions/v1/$functionName');
    final reqHeaders = <String, String>{
      ...merged,
      // Required by Edge Functions gateway.
      'apikey': SupabaseConfig.anonKey,
    };

    http.Response resp;
    if (files != null && files.isNotEmpty) {
      if (body != null && body is! Map) {
        throw ArgumentError('Multipart invoke expects body as Map<String, dynamic> fields or null');
      }
      final multipart = http.MultipartRequest('POST', url);
      final h = Map<String, String>.from(reqHeaders);
      h.remove('Content-Type');
      multipart.headers.addAll(h);
      if (body != null) {
        final map = body is Map<String, dynamic>
            ? body
            : Map<String, dynamic>.from(body as Map);
        map.forEach((k, v) {
          if (v != null) multipart.fields[k.toString()] = '$v';
        });
      }
      multipart.files.addAll(files);
      if (kDebugMode) {
        developer.log(
          '→ POST multipart $url files=${files.length} (auth=${withUserAuthorization ? 'yes' : 'no'})',
          name: 'EdgeFn',
        );
      }
      final streamed = await multipart.send();
      resp = await http.Response.fromStream(streamed);
    } else {
      reqHeaders['Content-Type'] = 'application/json';
      final payload = switch (body) {
        null => null,
        String() => body,
        List<int>() => body,
        _ => jsonEncode(body),
      };

      if (kDebugMode) {
        developer.log('→ POST $url (auth=${withUserAuthorization ? 'yes' : 'no'})', name: 'EdgeFn');
        if (payload is String) {
          final p = payload;
          developer.log('payload: ${p.length > 600 ? '${p.substring(0, 600)}…' : p}', name: 'EdgeFn');
        }
      }

      resp = await http.post(url, headers: reqHeaders, body: payload);
    }

    // Keep compatibility with FunctionResponse's dynamic `data`.
    Object? data;
    if (resp.body.isNotEmpty) {
      final ct = resp.headers['content-type'] ?? resp.headers['Content-Type'] ?? '';
      final isJson = ct.toLowerCase().contains('application/json');
      if (isJson) {
        try {
          data = jsonDecode(resp.body);
        } catch (_) {
          data = resp.body;
        }
      } else {
        data = resp.body;
      }
    }
    if (kDebugMode) {
      final b = resp.body;
      developer.log('← ${resp.statusCode} ${sw.elapsedMilliseconds}ms · POST $url', name: 'EdgeFn');
      if (b.isNotEmpty) {
        developer.log('body: ${b.length > 900 ? '${b.substring(0, 900)}…' : b}', name: 'EdgeFn');
      }
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return FunctionResponse(status: resp.statusCode, data: data);
    }
    throw AuthException(resp.body.isNotEmpty ? resp.body : 'Edge function error');
  }
}
