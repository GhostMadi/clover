import 'package:clover/feature/location/data/models/location_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LocationRepository {
  /// Все местоположения текущего пользователя (активные и неактивные).
  Future<List<LocationModel>> listMine();

  /// Местоположение по id (только своё, иначе null).
  Future<LocationModel?> getById(String id);

  /// Создание: обязателен [addressPrimary]; [isActive] по умолчанию true на сервере.
  Future<LocationModel> create({
    required String addressPrimary,
    String? addressCyrillic,
    double? latitude,
    double? longitude,
  });

  /// Обновление адреса, привязки страны/города и/или флага активности.
  Future<LocationModel> update({
    required String id,
    String? addressPrimary,
    String? addressCyrillic,
    bool clearAddressCyrillic = false,
    String? countryCode,
    String? cityCode,
    bool clearGeoBinding = false,
    bool? isActive,
  });

  /// Удаление своего местоположения.
  Future<void> delete({required String id});
}

@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _columns = '''
id,
address_primary,
address_cyrillic,
latitude,
longitude,
country_code,
city_code,
is_active,
created_at,
updated_at
''';

  String? get _uid => _client.auth.currentUser?.id;

  void _requireSession() {
    if (_uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
  }

  @override
  Future<List<LocationModel>> listMine() async {
    _requireSession();

    final data = await _client
        .from('locations')
        .select(_columns)
        .order('created_at', ascending: false);

    final list = data as List<dynamic>;
    return list
        .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<LocationModel?> getById(String id) async {
    _requireSession();
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final row = await _client.from('locations').select(_columns).eq('id', trimmed).maybeSingle();
    if (row == null) return null;
    return LocationModel.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<LocationModel> create({
    required String addressPrimary,
    String? addressCyrillic,
    double? latitude,
    double? longitude,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }

    final primary = addressPrimary.trim();
    if (primary.isEmpty) {
      throw ArgumentError('Пустой addressPrimary');
    }

    final cyrillic = addressCyrillic?.trim();
    final hasLat = latitude != null;
    final hasLng = longitude != null;
    if (hasLat != hasLng) {
      throw ArgumentError('latitude и longitude должны быть заданы вместе');
    }

    final insertRow = <String, dynamic>{
      'owner_id': uid,
      'address_primary': primary,
      if (cyrillic != null && cyrillic.isNotEmpty) 'address_cyrillic': cyrillic,
      if (hasLat) 'latitude': latitude,
      if (hasLng) 'longitude': longitude,
    };

    final inserted = await _client.from('locations').insert(insertRow).select(_columns).single();
    return LocationModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<LocationModel> update({
    required String id,
    String? addressPrimary,
    String? addressCyrillic,
    bool clearAddressCyrillic = false,
    String? countryCode,
    String? cityCode,
    bool clearGeoBinding = false,
    bool? isActive,
  }) async {
    _requireSession();
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Пустой id');
    }

    final patch = <String, dynamic>{};

    if (addressPrimary != null) {
      final primary = addressPrimary.trim();
      if (primary.isEmpty) {
        throw ArgumentError('Пустой addressPrimary');
      }
      patch['address_primary'] = primary;
    }

    if (clearAddressCyrillic) {
      patch['address_cyrillic'] = null;
    } else if (addressCyrillic != null) {
      final cyrillic = addressCyrillic.trim();
      patch['address_cyrillic'] = cyrillic.isEmpty ? null : cyrillic;
    }

    if (clearGeoBinding) {
      patch['country_code'] = null;
      patch['city_code'] = null;
    } else {
      final country = countryCode?.trim().toLowerCase();
      final city = cityCode?.trim();

      if (country != null || city != null) {
        if (country == null || country.isEmpty || city == null || city.isEmpty) {
          throw ArgumentError('countryCode и cityCode должны быть заданы вместе');
        }
        patch['country_code'] = country;
        patch['city_code'] = city;
      }
    }

    if (isActive != null) {
      patch['is_active'] = isActive;
    }

    if (patch.isEmpty) {
      final existing = await getById(trimmed);
      if (existing == null) {
        throw StateError('Местоположение не найдено');
      }
      return existing;
    }

    final updated = await _client
        .from('locations')
        .update(patch)
        .eq('id', trimmed)
        .select(_columns)
        .maybeSingle();

    if (updated == null) {
      throw StateError('Местоположение не найдено');
    }

    return LocationModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> delete({required String id}) async {
    _requireSession();
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Пустой id');
    }
    await _client.from('locations').delete().eq('id', trimmed);
  }
}
