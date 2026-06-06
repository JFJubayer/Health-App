import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/input_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';
import 'hive/entities/hive_type_registry.dart';
import 'services/persistence_service.dart';
import 'hive/seed/seed_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  String? startupError;

  try {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init('${appDir.path}/smart_diet_assistant_hive');
    registerHiveAdapters();

    await PersistenceService.initHive();
    await SeedService.seedIfNeeded();
  } catch (e, stackTrace) {
    startupError = e.toString();
    debugPrint('Startup failed: $e');
    debugPrint(stackTrace.toString());
  }

  if (startupError != null) {
    runApp(MaterialApp(
      home: _StartupErrorScreen(message: startupError),
    ));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SmartDietApp(),
    ),
  );
}

class SmartDietApp extends StatelessWidget {
  const SmartDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Smart Diet Assistant',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.isLoading) {
                // Return an empty container while loading, as the native splash screen is covering it.
                return const Scaffold(
                  body: SizedBox.expand(),
                );
              }

              // Data has loaded, remove the native splash screen.
              FlutterNativeSplash.remove();

              if (userProvider.user != null) {
                return const MainNavigation();
              }

              return const InputScreen();
            },
          ),
        );
      },
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final String message;

  const _StartupErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Could not start the app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you see a lock error, quit other running copies of this app and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
