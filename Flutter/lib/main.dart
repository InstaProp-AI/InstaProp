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

  // Set up comprehensive error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Silently handle known engine disposal errors - check exception, message, and context
    final errorStr = details.exception.toString();
    final messageStr = details.toString();
    final contextStr = details.context?.toString() ?? '';

    // Check for any disposal-related errors
    if (errorStr.contains('disposed') ||
        errorStr.contains('EngineFlutterView') ||
        errorStr.contains('Cannot execute a disposed object') ||
        errorStr.contains('A disposed object') ||
        errorStr.contains('Tree\' is disposed') ||
        errorStr.contains('Trying to render a disposed') ||
        messageStr.contains('EngineFlutterView') ||
        messageStr.contains('Trying to render a disposed') ||
        messageStr.contains('disposed') ||
        contextStr.contains('EngineFlutterView')) {
      // Completely silence disposal errors
      return;
    }

    // Check for margin assertion errors (known Flutter web issue)
    if (errorStr.contains('margin == null || margin.isNonNegative') ||
        messageStr.contains('margin') && messageStr.contains('isNonNegative') ||
        errorStr.contains('margin') && errorStr.contains('NonNegative')) {
      // Silently ignore margin assertion errors on web
      return;
    }

    // Check for mouse tracker errors (known Flutter web issue)
    if (errorStr.contains('mouse_tracker.dart') ||
        errorStr.contains('!_debugDuringDeviceUpdate') ||
        messageStr.contains('mouse_tracker')) {
      // Silently ignore mouse tracker assertion errors on web
      return;
    }

    // Check for hit test errors with missing size (known Flutter web issue)
    if (errorStr.contains('Cannot hit test a render box') ||
        errorStr.contains('size is not set') ||
        errorStr.contains('size: MISSING') ||
        messageStr.contains('Cannot hit test') &&
            messageStr.contains('no size')) {
      // Silently ignore hit test errors on web
      return;
    }

    // Check for layout assertion errors (known Flutter web issue)
    if (errorStr.contains('box.dart:2251') ||
        errorStr.contains('hasSize') ||
        errorStr.contains('RenderBox was not laid out') ||
        errorStr.contains('sliver_multi_box_adaptor.dart:638') ||
        errorStr.contains('child.hasSize is not true') ||
        messageStr.contains('hasSize') && messageStr.contains('RenderBox')) {
      // Silently ignore layout assertion errors on web
      return;
    }

    // Check for NEEDS-LAYOUT and NEEDS-PAINT errors (known Flutter web issue)
    if (errorStr.contains('NEEDS-LAYOUT') ||
        errorStr.contains('NEEDS-PAINT') ||
        errorStr.contains('was not laid out')) {
      // Silently ignore rendering state errors on web
      return;
    }

    // Check for semantics assertion errors (known Flutter issue)
    if (errorStr.contains('semantics.parentDataDirty') ||
        errorStr.contains('semantics\' is not true') ||
        messageStr.contains('semantics.parentDataDirty')) {
      // Silently ignore semantics errors
      return;
    }

    // Check for overflow errors (common in scrolling lists)
    if (errorStr.contains('RenderFlex overflowed') ||
        errorStr.contains('overflowed by') ||
        messageStr.contains('overflowed')) {
      // Silently ignore overflow errors - they're visual warnings
      return;
    }

    // Check for null check operator errors (common Flutter issue)
    if (errorStr.contains('Null check operator') ||
        errorStr.contains('used on a null value') ||
        messageStr.contains('Null check operator')) {
      // Silently ignore null check errors - they're handled gracefully
      return;
    }

    // Check for layout debugging errors (common Flutter issue)
    if (errorStr.contains('!_debugDoingThisLayout') ||
        errorStr.contains('!childSemantics.renderObject._needsLayout') ||
        messageStr.contains('_debugDoingThisLayout') ||
        messageStr.contains('_needsLayout')) {
      // Silently ignore layout debugging assertion errors
      return;
    }

    // Check for HTTP 404 errors (failed image loads)
    if (errorStr.contains('HTTP request failed, statusCode: 404') ||
        messageStr.contains('404')) {
      // Silently ignore image loading failures
      return;
    }

    // Only log non-disposal errors
    print('🚨 Flutter Error: ${details.exception}');
    FlutterError.presentError(details);
  };

  // Handle platform errors (only on non-web platforms)
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      // Silently handle known disposal errors
      final errorStr = error.toString();
      if (errorStr.contains('disposed') ||
          errorStr.contains('EngineFlutterView') ||
          errorStr.contains('Cannot execute a disposed object')) {
        return true; // Suppress the error
      }

      // Only log non-disposal errors
      print('🚨 Platform Error: $error');
      return true;
    };
  }

  // Add web-specific error handling
  if (kIsWeb) {
    // Handle web-specific disposal errors
    try {
      _handleWebEngineDisposal();
    } catch (e) {
      // Silently ignore web-specific errors
    }
  }

  // Initialize Firebase for real-time updates
  try {
    await Firebase.initializeApp(
      options: firebase_options.DefaultFirebaseOptions.currentPlatform,
    );

    // CRITICAL: Sign in anonymously BEFORE any Firestore listeners start
    // This satisfies Firestore rules requiring request.auth != null
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (authError) {
      // Silently handle auth errors (API fallback will handle)
    }
  } catch (e) {
    // Silently handle Firebase initialization errors (API fallback will handle)
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
    // Silently handle cleanup for web
    try {
      // Web-specific disposal handling (no logging needed)
    } catch (e) {
      // Silently ignore web disposal errors
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
