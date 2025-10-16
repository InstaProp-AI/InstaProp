import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';

/// Main app widget
class PropertyFlipperApp extends StatelessWidget {
  const PropertyFlipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.init(); // Initialize app state
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
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}
