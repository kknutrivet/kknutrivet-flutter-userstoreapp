import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web configuration for the shared `kk-nutrivet-web` Firebase project.
///
/// Android reads the same project from `android/app/google-services.json`
/// (merged at build time), so it must keep passing `null` options to
/// `Firebase.initializeApp`.
const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyDcsOwec0DXCgXTYXOAIdhBCM40Xxi-9vw',
  authDomain: 'kk-nutrivet-web.firebaseapp.com',
  projectId: 'kk-nutrivet-web',
  storageBucket: 'kk-nutrivet-web.firebasestorage.app',
  messagingSenderId: '446688659304',
  appId: '1:446688659304:web:5a80415d18c21dffc0f8dd',
);

FirebaseOptions? get platformFirebaseOptions =>
    kIsWeb ? firebaseWebOptions : null;
