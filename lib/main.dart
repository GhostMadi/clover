import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/config/supabase.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/network/supabase_logging_http_client.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    debug: supabaseHttpLoggingEnabled,
    httpClient: supabaseHttpLoggingEnabled ? SupabaseLoggingHttpClient() : null,
  );

  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<AuthCubit>()..checkAuth(), child: const _MyAppView());
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
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      title: 'Clover',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.pageBackground,
        progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.pageBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyle.base(20, color: AppColors.textColor, fontWeight: FontWeight.w500),
        ),
        useMaterial3: true,
      ),
    );
  }
}
