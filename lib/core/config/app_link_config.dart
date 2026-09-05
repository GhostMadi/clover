/// Deep link / universal link hosts and scheme for Clover.
class AppLinkConfig {
  const AppLinkConfig._();

  static const customScheme = 'clover';

  /// HTTPS hosts that open the app (Associated Domains on iOS).
  static const httpsHosts = {'clover.app', 'www.clover.app', 'app.clover.kz'};

  static const defaultHostDisplayName = 'Clover';

  /// Example: `https://clover.app/p/{postId}` or `clover://p/{postId}`.
  static String post(String postId) => 'https://clover.app/p/$postId';

  static String profile(String userId) => 'https://clover.app/u/$userId';

  static String bookHost(String hostId, {String? serviceId}) {
    final base = 'https://clover.app/book/$hostId';
    if (serviceId == null || serviceId.trim().isEmpty) return base;
    return '$base?service=${Uri.encodeComponent(serviceId.trim())}';
  }

  static String myBooking(String bookingId) => 'https://clover.app/bookings/mine/$bookingId';

  static String hostBooking(String bookingId) => 'https://clover.app/bookings/host/$bookingId';
}
