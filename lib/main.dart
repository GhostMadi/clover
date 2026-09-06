import 'dart:async';

import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/config/supabase.dart';
import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/debug/app_shake_logger_config.dart';
import 'package:clover/core/debug/app_shake_logger_host.dart';
import 'package:clover/core/debug/app_talker.dart';
import 'package:clover/core/deep_link/app_deep_link_service.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/network/supabase_logging_http_client.dart';
import 'package:clover/core/push/app_push_messaging_service.dart';
import 'package:clover/core/router/app_router.dart';
import 'package:clover/core/theme/app_color_binding.dart';
import 'package:clover/core/theme/app_colors_scope.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:clover/core/theme/app_theme.dart';
import 'package:clover/core/theme/app_theme_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (AppShakeLoggerConfig.enabled) {
        FlutterError.onError = (details) {
          appTalker.handle(details.exception, details.stack, 'FlutterError');
          FlutterError.presentError(details);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          appTalker.handle(error, stack, 'Platform');
          return true;
        };
      }

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
        debug: false,
        httpClient: supabaseHttpLoggingEnabled ? SupabaseLoggingHttpClient() : null,
      );
      await configureDependencies();
      await sl<AppThemeCubit>().load();
      await sl<AppDeepLinkService>().init();
      await sl<AppPushMessagingService>().init();

      if (AppShakeLoggerConfig.enabled) {
        AppLog.i('Clover started', tag: 'App');
      }

      runApp(const MyApp());
    },
    (error, stack) {
      appTalker.handle(error, stack, 'Zone');
    },
    zoneSpecification: AppShakeLoggerConfig.enabled
        ? ZoneSpecification(
            print: (self, parent, zone, line) {
              appTalker.debug(line);
              parent.print(zone, line);
            },
          )
        : null,
  );
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
  void initState() {
    super.initState();
    sl<AppDeepLinkService>().bindRouter(_appRouter);
  }

  @override
  void dispose() {
    unawaited(sl<AppDeepLinkService>().dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeCubit>().state;

    return MaterialApp.router(
      routerConfig: _appRouter.config(
        navigatorObservers: () => [if (AppShakeLoggerConfig.enabled) TalkerRouteObserver(appTalker)],
      ),
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

        Widget content = AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: AppColorsScope(
            palette: palette,
            child: AppThemeTreeRebuilder(palette: palette, child: child ?? const SizedBox.shrink()),
          ),
        );

        if (AppShakeLoggerConfig.enabled) {
          content = TalkerWrapper(
            talker: appTalker,
            options: const TalkerWrapperOptions(enableErrorAlerts: false),
            child: AppShakeLoggerHost(navigatorKey: _appRouter.navigatorKey, child: content),
          );
        }

        return content;
      },
    );
  }
}
