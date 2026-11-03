import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/phone.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

/// Matches the website's AuthModal: a compact sign-in sheet with phone OTP
/// as the primary path, Google and guest as one-tap alternatives, and
/// email/password tucked behind a "use email instead" fallback. Browsing
/// (home, products, blog) never requires this — it only shows up when an
/// action actually needs an account, same as kknutrivet.in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _EmailMode { login, register }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Phone OTP (primary flow — direct SMS verification)
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _googleLoading = false;
  bool _dismissed = false;
  int _resendCountdown = 0;

  // Email fallback
  bool _showEmailFallback = false;
  _EmailMode _emailMode = _EmailMode.login;
  final _formKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regPhone = TextEditingController();
  final _regReferral = TextEditingController();
  bool _obscurePw = true;
  bool _showReferral = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider).value != null) {
        _dismissDialog();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regPhone.dispose();
    _regReferral.dispose();
    super.dispose();
  }

  Future<void> _tick(int seconds) async {
    setState(() => _resendCountdown = seconds);
    while (_resendCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
    }
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    final phone = normalizeIndianPhone(rawPhone);
    if (phone.length != 10) {
      showToast('Enter a valid 10-digit mobile number', isError: true);
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      await ref.read(authServiceProvider).sendOtp(phone, _regName.text.trim());
      setState(() => _otpSent = true);
      _tick(30);
      showToast('OTP sent to +91 $phone');
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException) {
        msg = e.message;
      } else {
        msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
      }
      showToast(msg, isError: true);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final rawPhone = _phoneController.text.trim();
    final phone = normalizeIndianPhone(rawPhone);
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      showToast('Enter the OTP sent to your mobile', isError: true);
      return;
    }
    setState(() => _verifyingOtp = true);
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(
            phone,
            code,
            name: _regName.text.trim().isEmpty ? null : _regName.text.trim(),
            referralCode: _referralCodeOrNull(),
          );
      _dismissDialog();
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException) {
        msg = e.message;
      } else {
        msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
      }
      showToast(msg, isError: true);
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signInWithGoogle(referralCode: _referralCodeOrNull());
      if (ref.read(authProvider).value != null) {
        _dismissDialog();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is FirebaseAuthException) {
          msg = e.message ?? e.code;
        } else if (e is ApiException) {
          msg = e.message;
        } else {
          msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
        }
        showToast(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _dismissDialog() {
    if (_dismissed || !mounted) return;
    _dismissed = true;

    PushService.instance.resyncToken(
      ({required String token, String? previousToken}) => ref
          .read(notificationServiceProvider)
          .registerPushToken(
            token: token,
            previousToken: previousToken,
            userAgent: PushService.userAgent,
          ),
    );

    final pending = ref.read(pendingAuthRedirectProvider);
    ref.read(pendingAuthRedirectProvider.notifier).state = null;
    final target = (pending == null || pending == '/login') ? null : pending;

    if (target != null) {
      context.go(target);
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  String? _referralCodeOrNull() {
    final code = _regReferral.text.trim();
    return code.isEmpty ? null : code;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user != null && !_dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dismissDialog();
      });
    }

    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            _dismissDialog();
          }
        },
        error: (e, _) {
          String msg = e.toString();
          if (e is FirebaseAuthException) {
            msg = e.message ?? e.code;
          } else if (e is ApiException) {
            msg = e.message;
          } else {
            msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
          }
          if (msg.isNotEmpty) {
            showToast(msg, isError: true);
          }
        },
      );
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Semi-transparent backdrop overlay with blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    const Color(0xBB08271E), // rgba(8, 39, 30, 0.73)
                    BlendMode.srcOver,
                  ),
                  child: Container(color: const Color(0x9908271E)),
                ),
              ),
            ),
            // 2. Centered dialog card (AuthModal)
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 16,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 364),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4008271E),
                          blurRadius: 40,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _header(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                16,
                              ),
                              child: _showEmailFallback
                                  ? _emailFallbackForm(authState)
                                  : _quickAuthBody(authState),
                            ),
                          ],
                        ),
                        // Close 'X' button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Color(0xFF5A615F),
                            ),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
                          ),
                        ),
                        // Top grabber handle
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0x4707583F),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        // Close button on top right
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Material(
                            color: const Color(0xF5FFFDF8),
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/home'),
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFFD8E5DE),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1217322B),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                  color: Color(0xFF07583F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FAF6),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE8E0))),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryDeep,
              child: Icon(Icons.pets, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 12,
                color: Color(0xFF5A615F),
              ),
              const SizedBox(width: 4),
              const Text(
                'Secure sign-in',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A615F),
                ),
              ),
              Container(
                width: 1,
                height: 10,
                color: const Color(0xFFB8DCCD),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Text(
                'Fast checkout',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A615F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAuthBody(AsyncValue authState) {
    final canSubmit = _phoneController.text.trim().length == 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_otpSent) ...[
          // Google button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: (_googleLoading || authState.isLoading)
                  ? null
                  : _signInWithGoogle,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD5E4DE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _googleLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : SvgPicture.string(
                            '''<svg width="20" height="20" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
                              <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
                              <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
                              <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238A11.91 11.91 0 0 1 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
                              <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303a12.04 12.04 0 0 1-4.087 5.571l.001-.001 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
                            </svg>''',
                            width: 18,
                            height: 18,
                          ),
                    const SizedBox(width: 10),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF17322B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: Color(0xFFE6F1EA), height: 1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR USE MOBILE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A9490),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: Color(0xFFE6F1EA), height: 1),
                ),
              ],
            ),
          ),
          // Mobile input label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MOBILE NUMBER',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A615F),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'No password needed',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF07583F),
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5E4DE)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.phone_iphone_outlined,
                  size: 18,
                  color: Color(0xFF8A9490),
                ),
                const SizedBox(width: 6),
                const Text(
                  '🇮🇳  +91',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17322B),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF8A9490),
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: const Color(0xFFE2EBE5),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    maxLength: 10,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '9876543210',
                      hintStyle: TextStyle(
                        color: Color(0xFF8A9490),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF17322B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 44,
            child: ElevatedButton(
              onPressed: (_sendingOtp || !canSubmit) ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07583F),
                disabledBackgroundColor: const Color(0xFF76A696),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _sendingOtp
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue with mobile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (_showReferral) ...[
            const SizedBox(height: 8),
            _referralBanner(),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () => setState(() => _showReferral = true),
                  child: const Text(
                    'Have a referral code?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A615F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ] else ...[
          Text(
            'OTP sent to +91 ${_phoneController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otpController,
            autofillHints: const [AutofillHints.oneTimeCode],
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: (authState.isLoading || _verifyingOtp)
                ? null
                : _verifyOtp,
            child: (authState.isLoading || _verifyingOtp)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify & Continue'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                  _otpController.clear();
                }),
                child: const Text('Change number'),
              ),
              TextButton(
                onPressed: _resendCountdown > 0 ? null : _sendOtp,
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend in ${_resendCountdown}s'
                      : 'Resend OTP',
                ),
              ),
            ],
          ),
        ],

        // Guest card
        _guestButton(authState),

        // Privacy disclaimer
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'Sign-in uses the data described in our Privacy Policy. Analytics and marketing stay under Privacy Choices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF8A9490),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _referralBanner() {
    if (_regReferral.text.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Referral applied: ${_regReferral.text}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => setState(() => _regReferral.clear()),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }
    if (_showReferral) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _regReferral,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Referral code',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showReferral = false),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: () => setState(() => _showReferral = true),
      icon: const Icon(Icons.card_giftcard, size: 16),
      label: const Text(
        'Have a referral code? Get bonus points',
        style: TextStyle(fontSize: 11.5),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(38),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
    );
  }

  Widget _guestButton(AsyncValue authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF7FF), Color(0xFFF1ECFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CFF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Guest mode is active',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4D367E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'GUEST ACTIVE',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your cart and pet data are safe here. Verify your mobile to order and use them across devices.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF756D85),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailFallbackForm(AsyncValue authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _showEmailFallback = false),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              'Back to quick login',
              style: TextStyle(fontSize: 12.5),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),
          if (_emailMode == _EmailMode.register) ...[
            TextFormField(
              controller: _regName,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPhone,
              keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'Phone (10 digits)'),
              validator: (v) =>
                  (v == null || v.length != 10) ? 'Enter a valid phone' : null,
            ),
            TextFormField(
              controller: _regPassword,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePw ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regReferral,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Referral code (optional)',
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await ref
                              .read(authProvider.notifier)
                              .register(
                                email: _regEmail.text.trim(),
                                password: _regPassword.text,
                                name: _regName.text.trim(),
                                phone: _regPhone.text.trim(),
                                referralCode: _regReferral.text.trim().isEmpty
                                    ? null
                                    : _regReferral.text.trim(),
                              );
                          _dismissDialog();
                        } catch (_) {}
                      }
                    },
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _emailMode = _EmailMode.login),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _loginEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loginPassword,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePw ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot?', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await ref
                              .read(authProvider.notifier)
                              .login(
                                _loginEmail.text.trim(),
                                _loginPassword.text,
                              );
                          _dismissDialog();
                        } catch (_) {}
                      }
                    },
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _emailMode = _EmailMode.register),
                child: const Text("New here? Create an account"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
