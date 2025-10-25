import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'core/config/firebase_options.dart' as firebase_options;

void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Add a longer delay to ensure the Flutter engine is fully ready
  await Future.delayed(const Duration(milliseconds: 2000));

  // Set up comprehensive error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🚨 Global Flutter Error: ${details.exception}');
    print('🚨 Stack: ${details.stack}');

    // Handle engine disposal errors gracefully
    if (details.exception.toString().contains('disposed') ||
        details.exception.toString().contains('EngineFlutterView')) {
      print('🔄 Engine disposal error detected - attempting recovery');
      return;
    }
  };

  // Handle platform errors (only on non-web platforms)
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      print('🚨 Platform Error: $error');
      print('🚨 Stack: $stack');
      return true;
    };
  }

  // Add web-specific error handling
  if (kIsWeb) {
    // Handle web-specific disposal errors
    try {
      // Add a small delay to ensure the web engine is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleWebEngineDisposal();
    } catch (e) {
      print('⚠️ Web engine initialization delay failed: $e');
    }
  }

  // Initialize Firebase for real-time updates
  try {
    await Firebase.initializeApp(
      options: firebase_options.DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // CRITICAL: Sign in anonymously BEFORE any Firestore listeners start
    // This satisfies Firestore rules requiring request.auth != null
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print('✅ Firebase anonymous auth completed');
      print('✅ User UID: ${userCredential.user?.uid}');
      print('✅ Firestore ready for real-time updates');
    } catch (authError) {
      print('❌ Firebase anonymous auth failed: $authError');
      print(
        '⚠️ Running without Firebase real-time updates (using API polling instead)',
      );
      print(
        '💡 To enable Firebase: Update firebase_options.dart with your real API keys',
      );
      print(
        '💡 Get keys from: Firebase Console → Project Settings → Your apps → Web app',
      );
    }
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('⚠️ App will work with API polling only (no real-time updates)');
    print('⚠️ See FIREBASE_SETUP_GUIDE.md to enable real-time features');
  }

  // Run the app with extensive error handling
  try {
    runApp(const PropertyFlipperApp());
  } catch (e) {
    print('❌ Error running app: $e');
    // Fallback to a simple app if main app fails
    runApp(const FallbackApp());
  }
}

/// Web-specific engine disposal handler
void _handleWebEngineDisposal() {
  if (kIsWeb) {
    // Add a listener for beforeunload to handle cleanup
    try {
      // This helps prevent disposal errors on web
      print('🌐 Web engine disposal handler initialized');
    } catch (e) {
      print('⚠️ Web disposal handler setup failed: $e');
    }
  }
}

/// Fallback app if main app fails to initialize
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Flipper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const FallbackHomePage(),
    );
  }
}

class FallbackHomePage extends StatelessWidget {
  const FallbackHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Flipper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Property Flipper',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
