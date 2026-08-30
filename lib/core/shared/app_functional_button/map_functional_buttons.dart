import 'package:clover/core/resources/app_icons.dart';
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
      FunctionalButtonItem(icon: AppIcons.addRounded.icon, onTap: onZoomIn),
      FunctionalButtonItem(icon: AppIcons.removeRounded.icon, onTap: onZoomOut),
      FunctionalButtonItem(icon: AppIcons.myLocation.icon, onTap: onMyLocation),
    ];
  }
}
