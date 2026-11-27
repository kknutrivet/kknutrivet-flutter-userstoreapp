import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/firebase_options.dart';

/// Same Firebase project as the website (`src/lib/firebase.ts`).
///
/// The backend never sees Firebase SDKs — it only verifies Firebase ID
/// tokens (`/api/auth/firebase`, `/api/auth/firebase-phone`,
/// `/api/auth/firebase-anonymous`). So the app mints tokens with the
/// Firebase client SDKs against the SAME project and POSTs the ID token,
/// exactly like the web client does.
///
/// Console setup (one time, same project as the website):
/// 1. Add an Android app (package `com.nvit.nvit_app`) and an iOS app to
///    the existing Firebase project; download `google-services.json` into
///    `android/app/` and `GoogleService-Info.plist` into `ios/Runner/`.
/// 2. Register the Android SHA-1/SHA-256 fingerprints (debug + release) —
///    required for Google sign-in and phone auth.
/// 3. Enable the Phone + Google providers in Authentication → Sign-in method.
class FirebaseNotConfiguredException implements Exception {
  FirebaseNotConfiguredException([this.message = 'Firebase is not configured.']);
  final String message;
  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  bool _initialized = false;
  Future<void>? _googleInitFuture;

  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  Future<void> _ensureGoogleSignInInitialized() {
    // On Android, google_sign_in_android 7.2.x automatically reads
    // `default_web_client_id` generated from `android/app/google-services.json`.
    return _googleInitFuture ??= GoogleSignIn.instance
        .initialize(
          clientId: kIsWeb && _webClientId.isNotEmpty ? _webClientId : null,
        )
        .catchError((Object error, StackTrace stackTrace) {
          _googleInitFuture = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
  }

  /// Must be called (and awaited) before any other method. Returns true
  /// when Firebase is usable, false when the native config files are
  /// missing — callers fall back to email/guest instead of crashing.
  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: platformFirebaseOptions);
      }
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint(
        '[Firebase] initializeApp failed; Google/phone sign-in disabled: $e',
      );
      return false;
    }
  }

  void _requireReady() {
    if (!_initialized || Firebase.apps.isEmpty) {
      throw FirebaseNotConfiguredException();
    }
  }

  /// Fallback OAuth via Firebase Auth Chrome Custom Tab / Web popup.
  Future<String?> _signInWithGoogleWebFallback() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters(const {'prompt': 'select_account'});
      final userCredential = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      return idToken;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  /// Native Google sign-in (`google_sign_in` v7.2.0 / Android Credential
  /// Manager) → Firebase credential → ID token for POST /api/auth/firebase.
  ///
  /// Falls back automatically to Firebase Auth web OAuth if native sign-in
  /// is unsupported or fails for a non-cancellation reason.
  Future<String?> signInWithGoogle() async {
    _requireReady();
    try {
      await _ensureGoogleSignInInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return await _signInWithGoogleWebFallback();
      }
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleIdToken = googleUser.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        debugPrint(
          '[Firebase] Native Google Sign-In returned empty idToken; falling back to web OAuth.',
        );
        return await _signInWithGoogleWebFallback();
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      debugPrint(
        '[Firebase] Native Google Sign-In failed (${e.code}: ${e.description}); falling back to web OAuth.',
      );
      return await _signInWithGoogleWebFallback();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      debugPrint(
        '[Firebase] Native Google Sign-In PlatformException (${e.code}: ${e.message}); falling back to web OAuth.',
      );
      return await _signInWithGoogleWebFallback();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[Firebase] Native Google Sign-In error ($e); falling back to web OAuth.',
      );
      return await _signInWithGoogleWebFallback();
    }
  }

  /// Starts Firebase phone verification for a 10-digit Indian number.
  /// Mirrors `sendPhoneOtp` in `src/lib/firebase.ts` (web uses an
  /// invisible reCAPTCHA; on mobile the SDK handles verification
  /// automatically, including Android auto-retrieval).
  Future<void> sendPhoneOtp({
    required String phone10,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String message) onError,
    int? forceResendingToken,
  }) async {
    _requireReady();
    final digits = phone10.replaceAll(RegExp(r'\D'), '').replaceFirst(
          RegExp(r'^91'),
          '',
        );
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$digits',
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            onAutoVerified(idToken);
          }
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (e) => onError(e.message ?? e.code),
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Verifies the SMS code → Firebase credential → ID token for
  /// POST /api/auth/firebase-phone. Mirrors `verifyPhoneOtp`.
  Future<String> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    _requireReady();
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Phone verification did not return an ID token.',
      );
    }
    return idToken;
  }

  /// Anonymous Firebase sign-in → ID token for
  /// POST /api/auth/firebase-anonymous. Mirrors the website's
  /// "Continue as guest" path.
  Future<String> signInAnonymously() async {
    _requireReady();
    final userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Guest sign-in did not return an ID token.',
      );
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;
    try {
      if (_googleInitFuture != null) {
        await _googleInitFuture;
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
