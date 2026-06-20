import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:flutter/material.dart';

/// Кнопки управления картой для [AppFunctionalScreen].
abstract final class MapFunctionalButtons {
  static List<FunctionalButtonItem> controls({
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
    required VoidCallback onMyLocation,
  }) {
    return [
      FunctionalButtonItem(icon: Icons.add_rounded, onTap: onZoomIn),
      FunctionalButtonItem(icon: Icons.remove_rounded, onTap: onZoomOut),
      FunctionalButtonItem(icon: Icons.my_location_rounded, onTap: onMyLocation),
    ];
  }
}
