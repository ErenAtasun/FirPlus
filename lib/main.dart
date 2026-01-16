import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/onboarding/profile_wizard_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/add_meal/add_meal_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/weight/weight_tracking_screen.dart';
import 'models/meal_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatı için
  await initializeDateFormatting('tr_TR', null);

  // Web için Hive'ı burada başlat (main'de başlatmak daha güvenli)
  if (kIsWeb) {
    await Hive.initFlutter();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'Kalori Takip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AppWrapper(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        );

      case '/profile-wizard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ProfileWizardScreen(
            isEditing: args?['isEditing'] ?? false,
          ),
        );

      case '/calendar':
        return MaterialPageRoute(
          builder: (context) => const CalendarScreen(),
        );

      case '/add-meal':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => AddMealScreen(
            initialMealType: args?['mealType'],
            editingMeal: args?['meal'] as MealEntry?,
          ),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        );

      case '/weight':
        return MaterialPageRoute(
          builder: (context) => const WeightTrackingScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const AppWrapper(),
        );
    }
  }
}

/// Uygulama başlangıç kontrolü
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yükleniyor...'),
                ],
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        // Profil yoksa wizard'a yönlendir
        if (!provider.hasProfile) {
          return const ProfileWizardScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}

/// Ana navigasyon ekranı (Bottom Navigation)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const WeightTrackingScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Takvim',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight_outlined),
              activeIcon: Icon(Icons.monitor_weight),
              label: 'Kilo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
