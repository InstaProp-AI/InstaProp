import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PropertyFlipperApp());
}

class PropertyFlipperApp extends StatelessWidget {
  const PropertyFlipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.init(); // This is async but we don't await it
        return appState;
      },
      child: Builder(
        builder: (context) {
          final appState = Provider.of<AppState>(context, listen: false);
          return ChangeNotifierProvider.value(
            value: appState.notificationService,
            child: MaterialApp(
              title: 'Property Flipper',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.green,
                primaryColor: const Color(0xFF2E7D32),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2E7D32),
                  brightness: Brightness.light,
                  primary: const Color(0xFF2E7D32),
                  secondary: const Color(0xFF4CAF50),
                  surface: const Color(0xFFFAFAFA),
                  background: const Color(0xFFF5F5F5),
                ),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                cardTheme: CardThemeData(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(8),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                textTheme: const TextTheme(
                  headlineLarge: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  headlineMedium: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                  titleLarge: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                  bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF424242)),
                  bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF616161)),
                ),
              ),
              home: const AppRouter(),
              routes: {
                '/auth': (context) => const AuthPage(),
                '/profile': (context) => const ProfilePage(),
              },
            ),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // Always show home page immediately - authentication will be handled within pages
    return const HomePage();
  }
}
