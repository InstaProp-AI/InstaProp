import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';
import 'pages/profile_page.dart';
import 'theme/app_theme.dart';

// Import Firebase options if available
// If firebase_options.dart doesn't exist, run: flutterfire configure
// See FIREBASE_SETUP_GUIDE.md for detailed instructions
import 'firebase_options.dart' as firebase_options;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for real-time updates
  try {
    await Firebase.initializeApp(
      options: firebase_options.DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('⚠️ App will work with API polling only (no real-time updates)');
    print('⚠️ See FIREBASE_SETUP_GUIDE.md to enable real-time features');
  }
  
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
              theme: AppTheme.lightTheme,
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
