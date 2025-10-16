import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'core/config/firebase_options.dart' as firebase_options;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const PropertyFlipperApp());
}
