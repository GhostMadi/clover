import 'package:clover/core/shared/app_map/app_map.dart';
import 'package:clover/feature/_catalog_/location/presentation/widget/location_create_address_bar.dart';
import 'package:flutter/material.dart';

/// Карта создания местоположения: [AppMap] + панель адреса сверху.
class LocationCreateMapView extends StatelessWidget {
  const LocationCreateMapView({
    super.key,
    required this.cyrillicController,
    required this.secondaryController,
    required this.initialCenter,
    required this.selectedPoint,
    required this.onPointSelected,
    required this.mapController,
  });

  final TextEditingController cyrillicController;
  final TextEditingController secondaryController;
  final AppMapPoint initialCenter;
  final AppMapPoint? selectedPoint;
  final ValueChanged<AppMapPoint> onPointSelected;
  final AppMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AppMap(
            controller: mapController,
            initialCenter: initialCenter,
            selectedPoint: selectedPoint,
            onPointSelected: onPointSelected,
          ),
        ),
        LocationCreateAddressBar(
          cyrillicController: cyrillicController,
          secondaryController: secondaryController,
        ),
      ],
    );
  }
}
