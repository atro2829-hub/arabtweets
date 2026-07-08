import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/api_constants.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    publishableKey: ApiConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;

  runApp(
    ProviderScope(
      child: ArabtweetsApp(isDark: isDark),
    ),
  );
}

class ArabtweetsApp extends ConsumerStatefulWidget {
  final bool isDark;

  const ArabtweetsApp({super.key, required this.isDark});

  @override
  ConsumerState<ArabtweetsApp> createState() => _ArabtweetsAppState();
}

class _ArabtweetsAppState extends ConsumerState<ArabtweetsApp> {
  @override
  void initState() {
    super.initState();
    // Initialize theme with stored preference
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: ApiConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Router
      routerConfig: appRouter,

      // Builder for responsive breakpoints and RTL direction
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}