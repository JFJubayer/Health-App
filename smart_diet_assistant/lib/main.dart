import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/input_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';


import 'package:hive_flutter/hive_flutter.dart';
import 'hive/entities/ingredient_entity.dart';
import 'hive/entities/meal_template_entity.dart';
import 'hive/entities/ingredient_portion_entity.dart';
import 'hive/entities/day_plan_entity.dart';
import 'hive/entities/meal_memory_entity.dart';
import 'hive/entities/user_meal_preference_entity.dart';
import 'models/meal_model.dart';
import 'services/persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(IngredientEntityAdapter());
  Hive.registerAdapter(MealTemplateEntityAdapter());
  Hive.registerAdapter(IngredientPortionAdapter());
  Hive.registerAdapter(DayPlanEntityAdapter());
  Hive.registerAdapter(MealTypeAdapter());

  await PersistenceService.initHive();

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
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Loading your diet profile...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

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
