import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web configuration for the shared `kk-nutrivet-web` Firebase project.
///
/// Android reads the same project from `android/app/google-services.json`
/// (merged at build time), so it passes `null` options to
/// `Firebase.initializeApp`. For Web builds, pass the API key via
/// `--dart-define=FIREBASE_WEB_API_KEY=...` so no literal key is stored in git.
const String _firebaseWebApiKey = String.fromEnvironment(
  'FIREBASE_WEB_API_KEY',
);

const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: _firebaseWebApiKey,
  authDomain: 'kk-nutrivet-web.firebaseapp.com',
  projectId: 'kk-nutrivet-web',
  storageBucket: 'kk-nutrivet-web.firebasestorage.app',
  messagingSenderId: '446688659304',
  appId: '1:446688659304:web:5a80415d18c21dffc0f8dd',
);

FirebaseOptions? get platformFirebaseOptions =>
    kIsWeb && _firebaseWebApiKey.isNotEmpty ? firebaseWebOptions : null;
