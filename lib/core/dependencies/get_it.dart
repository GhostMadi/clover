import 'package:clover/core/config/google_auth_config.dart';
import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/dependencies/get_it.config.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // название метода генерации
  preferRelativeImports: true, // использовать относительные импорты
  asExtension: true, // генерация в виде расширения для GetIt
)
Future<void> configureDependencies() async {
  sl.init();
  // serverClientId (Web) обязателен: idToken.aud должен совпасть с Client ID в Supabase.
  // clientId (iOS) нужен на iOS; на Android берётся из google-services / package+SHA.
  await GoogleSignIn.instance.initialize(
    clientId: GoogleAuthConfig.iosClientId,
    serverClientId: GoogleAuthConfig.webClientId,
  );
}

/// Isar отдельно от FCM: на iPhone Release IsarCore иногда падает раньше APNs/токена.
Future<void> initAppStorage() async {
  try {
    await sl<IAppStorage>().init();
  } catch (error, stack) {
    AppLog.e('Isar init failed, retry…', tag: 'Storage', error: error, stackTrace: stack);
    await Sentry.captureException(error, stackTrace: stack);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await sl<IAppStorage>().init();
  }
}
