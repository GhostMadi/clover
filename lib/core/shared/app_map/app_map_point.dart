/// Географическая точка на карте.
class AppMapPoint {
  const AppMapPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppMapPoint && other.latitude == latitude && other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
