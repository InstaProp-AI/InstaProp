import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';
import 'pages/profile_page.dart';
import 'theme/app_theme.dart';

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
