import 'package:clover/core/catalog_sync/catalog_sync_kind.dart';
import 'package:clover/core/catalog_sync/data/dictionary_local_cache.dart';
import 'package:clover/core/catalog_sync/data/dictionary_network_source.dart';
import 'package:clover/core/catalog_sync/models/sync_meta.dart';
import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/countries/data/models/country_model.dart';
import 'package:clover/feature/currencies/data/models/currency_model.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';
import 'package:injectable/injectable.dart';

/// Синхронизация глобальных справочников по [SyncMeta] из ответа профиля.
@lazySingleton
class CatalogSyncManager {
  CatalogSyncManager(this._cache, this._network) {
    _entries = {
      CatalogSyncKind.countries: _CatalogEntry(
        kind: CatalogSyncKind.countries,
        fetchAll: () async => (await _network.fetchCountries()).cast<Object>(),
        fromJson: (json) => CountryModel.fromJson(json),
        toJson: (item) => (item as CountryModel).toJson(),
      ),
      CatalogSyncKind.cities: _CatalogEntry(
        kind: CatalogSyncKind.cities,
        fetchAll: () async => (await _network.fetchCities()).cast<Object>(),
        fromJson: (json) => CityModel.fromJson(json),
        toJson: (item) => (item as CityModel).toJson(),
      ),
      CatalogSyncKind.tags: _CatalogEntry(
        kind: CatalogSyncKind.tags,
        fetchAll: () async => (await _network.fetchMarkerTags()).cast<Object>(),
        fromJson: (json) => MarkerTagModel.fromJson(json),
        toJson: (item) => (item as MarkerTagModel).toJson(),
      ),
      CatalogSyncKind.currencies: _CatalogEntry(
        kind: CatalogSyncKind.currencies,
        fetchAll: () async => (await _network.fetchCurrencies()).cast<Object>(),
        fromJson: (json) => CurrencyModel.fromJson(json),
        toJson: (item) => (item as CurrencyModel).toJson(),
      ),
      CatalogSyncKind.categories: _CatalogEntry(
        kind: CatalogSyncKind.categories,
        fetchAll: () async => (await _network.fetchCategories()).cast<Object>(),
        fromJson: (json) => ProfileCategoryModel.fromJson(json),
        toJson: (item) => (item as ProfileCategoryModel).toJson(),
      ),
    };
  }

  final DictionaryLocalCache _cache;
  final DictionaryNetworkSource _network;

  late final Map<CatalogSyncKind, _CatalogEntry> _entries;

  SyncMeta? _lastRemoteMeta;
  final Map<CatalogSyncKind, Future<List<Object>>> _inFlight = {};

  SyncMeta? get lastRemoteMeta => _lastRemoteMeta;

  /// Сравнивает версии с Isar и обновляет только изменившиеся справочники.
  Future<void> validateAndSync(SyncMeta serverMeta) async {
    if (!serverMeta.isValid) return;

    _lastRemoteMeta = serverMeta;
    await Future.wait([
      for (final kind in CatalogSyncKind.values) _syncKindIfNeeded(kind, serverMeta),
    ]);
  }

  Future<List<CountryModel>> countries({SyncMeta? remoteMeta}) {
    return _resolve(CatalogSyncKind.countries, remoteMeta);
  }

  Future<List<CityModel>> cities({SyncMeta? remoteMeta}) {
    return _resolve(CatalogSyncKind.cities, remoteMeta);
  }

  Future<List<MarkerTagModel>> markerTags({SyncMeta? remoteMeta}) {
    return _resolve(CatalogSyncKind.tags, remoteMeta);
  }

  Future<List<CurrencyModel>> currencies({SyncMeta? remoteMeta}) {
    return _resolve(CatalogSyncKind.currencies, remoteMeta);
  }

  Future<List<ProfileCategoryModel>> categories({SyncMeta? remoteMeta}) {
    return _resolve(CatalogSyncKind.categories, remoteMeta);
  }

  Future<List<T>> _resolve<T>(CatalogSyncKind kind, SyncMeta? remoteMeta) async {
    final inFlight = _inFlight[kind];
    if (inFlight != null) return (await inFlight).cast<T>();

    final future = _resolveEntry(kind, remoteMeta);
    _inFlight[kind] = future;
    try {
      return (await future).cast<T>();
    } finally {
      _inFlight.remove(kind);
    }
  }

  Future<List<Object>> _resolveEntry(CatalogSyncKind kind, SyncMeta? remoteMeta) async {
    final entry = _entries[kind]!;
    final effectiveRemote = remoteMeta ?? _lastRemoteMeta;

    final remoteVersion = _remoteVersion(effectiveRemote, kind);
    final cached = await entry.readCached(_cache);

    if (cached != null && cached.isNotEmpty) {
      if (remoteVersion == null) return cached;
      final localVersion = await _cache.readVersion(kind);
      if (localVersion == remoteVersion) return cached;
    }

    try {
      return await entry.fetchAndPersist(_cache, remoteVersion);
    } catch (_) {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> _syncKindIfNeeded(CatalogSyncKind kind, SyncMeta remote) async {
    final entry = _entries[kind]!;
    final remoteVersion = remote.versionFor(kind);
    if (remoteVersion.isEmpty) return;

    final localVersion = await _cache.readVersion(kind);
    if (localVersion == remoteVersion) return;

    await entry.fetchAndPersist(_cache, remoteVersion);
  }

  String? _remoteVersion(SyncMeta? remote, CatalogSyncKind kind) {
    if (remote == null) return null;
    final version = remote.versionFor(kind);
    if (version.isEmpty) return null;
    return version;
  }
}

final class _CatalogEntry {
  const _CatalogEntry({
    required this.kind,
    required this.fetchAll,
    required this.fromJson,
    required this.toJson,
  });

  final CatalogSyncKind kind;
  final Future<List<Object>> Function() fetchAll;
  final Object Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(Object item) toJson;

  Future<List<Object>?> readCached(DictionaryLocalCache cache) {
    return cache.readList<Object>(
      kind: kind,
      fromJson: (json) => fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<List<Object>> fetchAndPersist(DictionaryLocalCache cache, String? remoteVersion) async {
    final fresh = await fetchAll();
    await cache.writeList<Object>(kind: kind, items: fresh, toJson: toJson);
    if (remoteVersion != null && remoteVersion.isNotEmpty) {
      await cache.writeVersion(kind, remoteVersion);
    }
    return fresh;
  }
}
