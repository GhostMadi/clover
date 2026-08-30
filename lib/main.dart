import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/config/supabase.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/network/supabase_logging_http_client.dart';
import 'package:clover/core/router/app_router.dart';
import 'package:clover/core/theme/app_color_binding.dart';
import 'package:clover/core/theme/app_colors_scope.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:clover/core/theme/app_theme.dart';
import 'package:clover/core/theme/app_theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    debug: false,
    httpClient: supabaseHttpLoggingEnabled ? SupabaseLoggingHttpClient() : null,
  );
  await configureDependencies();
  await sl<AppThemeCubit>().load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..checkAuth()),
        BlocProvider.value(value: sl<AppThemeCubit>()),
      ],
      child: const _MyAppView(),
    );
  }
}

class _MyAppView extends StatefulWidget {
  const _MyAppView();

  @override
  State<_MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<_MyAppView> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeCubit>().state;

    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      title: 'Clover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode.material,
      themeAnimationDuration: AppTheme.animationDuration,
      themeAnimationCurve: AppTheme.animationCurve,
      builder: (context, child) {
        final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
        AppColorBinding.palette = palette;

        final overlay = palette.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: AppColorsScope(
            palette: palette,
            child: AppThemeTreeRebuilder(palette: palette, child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
