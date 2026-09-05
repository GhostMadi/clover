import 'package:clover/core/resources/app_service_accent.dart';
import 'package:clover/core/theme/app_palette.dart';

/// Акцент продукта «Запись» — жёлтый сервисный стиль.
///
/// Менять цвет: `AppPalette.functionalSoftYellow` / `functionalSoftYellowIcon`
/// (и `borderCardYellow`) — все кнопки/поля с [kBookingService] подтянутся сами.
const AppServiceKind kBookingService = AppServiceKind.booking;

AppServiceAccent bookingServiceAccent(AppPalette colors) =>
    colors.serviceAccent(kBookingService);
