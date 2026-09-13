import 'package:clover/core/config/mapbox.dart';
import 'package:clover/core/debug/app_log.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Mapbox Standard: `basemap` import + `lightPreset` / `theme`.
/// Только после [StyleManager.isStyleLoaded] — иначе PlatformException.
class AppMapBasemapStyle {
  AppMapBasemapStyle._();

  static const importId = 'basemap';

  static Future<void> apply(MapboxMap map, {required bool isDark}) async {
    try {
      if (!await map.style.isStyleLoaded()) return;

      final imports = await map.style.getStyleImports();
      final hasBasemap = imports.any((item) => item?.id == importId);
      if (!hasBasemap) {
        AppLog.w('Mapbox import "$importId" missing (not Standard style?)', tag: 'AppMap');
        return;
      }

      await map.style.setStyleImportConfigProperty(importId, 'theme', 'default');
      await map.style.setStyleImportConfigProperty(
        importId,
        'lightPreset',
        isDark ? MapboxConfig.lightPresetNight : MapboxConfig.lightPresetDay,
      );
    } on PlatformException catch (error, stack) {
      AppLog.w(
        'Map basemap preset skipped · ${error.message ?? error.code}',
        tag: 'AppMap',
      );
      AppLog.d('Map basemap stack', tag: 'AppMap', error: error, stackTrace: stack);
    } catch (error, stack) {
      AppLog.e('Map basemap preset failed', tag: 'AppMap', error: error, stackTrace: stack);
    }
  }
}
