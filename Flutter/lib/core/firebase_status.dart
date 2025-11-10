import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config/firebase_options.dart' as firebase_options;

enum FirebaseAvailability { unknown, ready, unsupported, failed }

class FirebaseStatus {
  FirebaseStatus._();

  static FirebaseAvailability _availability = FirebaseAvailability.unknown;
  static Object? _lastError;
  static Completer<void>? _initializingCompleter;

  static final ValueNotifier<FirebaseAvailability> availabilityNotifier =
      ValueNotifier<FirebaseAvailability>(_availability);

  static FirebaseAvailability get availability => _availability;
  static bool get isReady => _availability == FirebaseAvailability.ready;
  static bool get isUnsupported =>
      _availability == FirebaseAvailability.unsupported;
  static bool get hasFailed => _availability == FirebaseAvailability.failed;
  static Object? get lastError => _lastError;

  static Future<void> ensureInitialized() async {
    if (_availability == FirebaseAvailability.ready ||
        _availability == FirebaseAvailability.unsupported ||
        _availability == FirebaseAvailability.failed) {
      return;
    }

    if (_initializingCompleter != null) {
      return _initializingCompleter!.future;
    }

    final completer = Completer<void>();
    _initializingCompleter = completer;

    try {
      final options = firebase_options.DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);

      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (authError) {
        _lastError = authError;
      }

      _availability = FirebaseAvailability.ready;
    } on UnsupportedError catch (unsupported) {
      _availability = FirebaseAvailability.unsupported;
      _lastError = unsupported;
    } catch (error) {
      _availability = FirebaseAvailability.failed;
      _lastError = error;
    } finally {
      availabilityNotifier.value = _availability;
      completer.complete();
      _initializingCompleter = null;
    }
  }
}


