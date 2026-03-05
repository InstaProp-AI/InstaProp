import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'services/onboarding_service.dart';
import 'widgets/floating_ai_broker_button.dart';

/// Error boundary widget to catch and handle errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Note: ErrorBoundary is now mostly handled globally in main.dart
    if (hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasError = false;
                    errorMessage = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Error page shown when app fails to build
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'App Initialization Failed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please restart the app',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // This would restart the app in a real scenario
                print('Restart requested');
              },
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Initial route widget that checks onboarding and auth status
class InitialRouteWidget extends StatefulWidget {
  const InitialRouteWidget({super.key});

  @override
  State<InitialRouteWidget> createState() => _InitialRouteWidgetState();
}

class _InitialRouteWidgetState extends State<InitialRouteWidget> {
  bool _isLoading = true;
  Widget? _initialRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineInitialRoute();
    });
  }

  Future<void> _determineInitialRoute() async {
    try {
      // Check if onboarding is completed
      final onboardingComplete = await OnboardingService.isOnboardingComplete();

      if (!onboardingComplete) {
        // Show onboarding for first-time users
        if (mounted) {
          setState(() {
            _initialRoute = const OnboardingPage();
            _isLoading = false;
          });
        }
        return;
      }

      // Always allow browsing - show HomePage (supports freemium/guest browsing)
      // Users can browse the app without logging in
      if (mounted) {
        setState(() {
          _initialRoute = const HomePage();
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, default to onboarding (safer for first-time users)
      // This ensures users see onboarding if there's any issue checking status
      if (mounted) {
        setState(() {
          _initialRoute = const OnboardingPage();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _initialRoute ?? const AuthPage();
  }
}

/// Main app widget
class InstapropApp extends StatelessWidget {
  const InstapropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        // Initialize app state with proper error handling
        Future.microtask(() {
          try {
            appState.init();
          } catch (e) {
            // Silently handle initialization errors
          }
        });
        return appState;
      },
      child: Builder(
        builder: (context) {
          try {
            final appState = Provider.of<AppState>(context, listen: false);
            return ChangeNotifierProvider.value(
              value: appState.notificationService,
              child: MaterialApp(
                title: 'Instaprop',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                onGenerateRoute: AppRouter.onGenerateRoute,
                home: const InitialRouteWidget(),
                // Add error boundary and floating button
                builder: (context, child) {
                  final appState = Provider.of<AppState>(context);
                  return ErrorBoundary(
                    child: Stack(
                      children: [
                        child ?? const SizedBox.shrink(),
                        if (appState.isFeatureEnabled('AIBroker'))
                          const FloatingAIBrokerButton(),
                      ],
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            return MaterialApp(
              title: 'Instaprop',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const ErrorPage(),
            );
          }
        },
      ),
    );
  }
}

/// Web-specific wrapper to handle disposal errors
class WebSafeWidget extends StatefulWidget {
  final Widget child;

  const WebSafeWidget({super.key, required this.child});

  @override
  State<WebSafeWidget> createState() => _WebSafeWidgetState();
}

class _WebSafeWidgetState extends State<WebSafeWidget> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
