import 'package:clover/core/dependencies/get_it.config.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

final sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // название метода генерации
  preferRelativeImports: true, // использовать относительные импорты
  asExtension: true, // генерация в виде расширения для GetIt
)
Future<void> configureDependencies() async {
  sl.init();
  await sl<IAppStorage>().init();
  await GoogleSignIn.instance.initialize();
}
