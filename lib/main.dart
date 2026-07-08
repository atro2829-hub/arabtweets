import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final isDark = prefs.getBool('isDarkMode') ?? false;

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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Router
      routerConfig: appRouter,

      // Builder for RTL and text direction
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}