import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static const _webClientId =
      '446688659304-cql9915fjkl985vqm88nhe3pdbpo04bf.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
  );

  /// Must be called (and awaited) before any other method. Returns true
  /// when Firebase is usable, false when the native config files are
  /// missing — callers fall back to email/guest instead of crashing.
  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _requireReady() {
    if (!_initialized || Firebase.apps.isEmpty) {
      throw FirebaseNotConfiguredException();
    }
  }

  /// Google sign-in → Firebase credential → ID token for
  /// POST /api/auth/firebase. Mirrors `signInWithGoogle` in
  /// `src/lib/firebase.ts` (+ `useAuthModalController`).
  Future<String?> signInWithGoogle() async {
    _requireReady();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
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
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      if (e.message != null && e.message!.contains('ApiException: 10')) {
        throw FirebaseAuthException(
          code: 'developer-error-10',
          message:
              'Google Sign-In configuration error (ApiException 10). Keystore SHA-1 must be registered in Firebase Console.',
        );
      }
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Google Sign-In failed.',
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
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
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
