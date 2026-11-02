import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/in_app_announcement.dart';
import '../network/api_client.dart';

class AnnouncementService {
  AnnouncementService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;
  static final AnnouncementService instance = AnnouncementService();

  static const String _storagePrefix = 'kknutrivet_dismissed_ann_';
  final Set<String> _sessionDismissedKeys = <String>{};
  bool _shownThisSession = false;

  bool get hasShownThisSession => _shownThisSession;

  void markShownThisSession() {
    _shownThisSession = true;
  }

  @visibleForTesting
  void resetSessionForTest() {
    _shownThisSession = false;
    _sessionDismissedKeys.clear();
  }

  String getDismissalKey(String id, int version) {
    final v = version > 1 ? '_v$version' : '_v1';
    return '$id$v';
  }

  Future<List<InAppAnnouncement>> fetchAnnouncements() async {
    try {
      final res = await _client.get('/announcements');
      if (res is! Map) return const [];
      final data = Map<String, dynamic>.from(res);

      final dynamic rawList = data['announcements'];
      final List<dynamic> list = rawList is List
          ? rawList
          : (data['announcement'] is Map ? [data['announcement']] : const []);

      final announcements = list
          .whereType<Map>()
          .map((item) => InAppAnnouncement.fromJson(Map<String, dynamic>.from(item)))
          .where((ann) => ann.isActive)
          .toList();

      // Sort by priority (1 is highest priority)
      announcements.sort((a, b) => a.priority.compareTo(b.priority));
      return announcements;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isDismissed(InAppAnnouncement ann) async {
    if (ann.id.isEmpty) return true;
    final vKey = getDismissalKey(ann.id, ann.version);

    if (_sessionDismissedKeys.contains(vKey)) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final versionedVal = prefs.getBool('$_storagePrefix$vKey');
      if (versionedVal == true) return true;

      // Legacy fallback for v1
      if (ann.version == 1) {
        final legacyVal = prefs.getBool('$_storagePrefix${ann.id}');
        if (legacyVal == true) return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> recordDismissal(InAppAnnouncement ann) async {
    if (ann.id.isEmpty) return;
    final vKey = getDismissalKey(ann.id, ann.version);
    _sessionDismissedKeys.add(vKey);
    _sessionDismissedKeys.add(ann.id);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_storagePrefix$vKey', true);
      await prefs.setBool('$_storagePrefix${ann.id}', true);
    } catch (_) {}
  }

  bool isEligibleForRoute(InAppAnnouncement ann, String currentRoute) {
    if (!ann.isActive) return false;

    // Route exclusions: auth, admin, onboarding, splash
    if (currentRoute.startsWith('/admin') ||
        currentRoute.startsWith('/login') ||
        currentRoute.startsWith('/forgot-password') ||
        currentRoute == '/splash' ||
        currentRoute == '/onboarding') {
      return false;
    }

    if (ann.target == 'HOMEPAGE_ONLY') {
      return currentRoute == '/home' || currentRoute == '/';
    }

    if (ann.target == 'CHECKOUT_ONLY') {
      return currentRoute == '/checkout' || currentRoute == '/cart';
    }

    return true; // 'ALL' target applies everywhere eligible
  }

  Future<InAppAnnouncement?> getNextEligibleAnnouncement({
    required String currentRoute,
    List<InAppAnnouncement>? preloadedAnnouncements,
  }) async {
    if (_shownThisSession) return null;

    final list = preloadedAnnouncements ?? await fetchAnnouncements();
    for (final ann in list) {
      if (!isEligibleForRoute(ann, currentRoute)) continue;
      if (await isDismissed(ann)) continue;
      return ann;
    }
    return null;
  }
}
