import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';

/// Последняя локация, выбранная в фильтре Events (не из профиля).
@lazySingleton
class EventsFilterLocationStore {
  EventsFilterLocationStore(this._storage);

  final IAppStorage _storage;

  static const _key = 'events_filter_last_location';

  Future<({String? countryCode, String? cityCode})> read() async {
    final raw = await _storage.read<Map<String, dynamic>>(key: _key);
    if (raw == null) return (countryCode: null, cityCode: null);

    final country = (raw['country_code'] as String?)?.trim().toLowerCase();
    final city = (raw['city_code'] as String?)?.trim().toLowerCase();

    return (
      countryCode: _isSet(country) ? country : null,
      cityCode: _isSet(city) ? city : null,
    );
  }

  Future<void> write({String? countryCode, String? cityCode}) async {
    final country = countryCode?.trim().toLowerCase();
    final city = cityCode?.trim().toLowerCase();

    if (!_isSet(country) && !_isSet(city)) {
      await _storage.delete(key: _key);
      return;
    }

    await _storage.write<Map<String, dynamic>>(
      key: _key,
      value: <String, dynamic>{
        if (_isSet(country)) 'country_code': country,
        if (_isSet(city)) 'city_code': city,
      },
    );
  }

  static bool _isSet(String? value) {
    final raw = value?.trim();
    return raw != null && raw.isNotEmpty;
  }
}
