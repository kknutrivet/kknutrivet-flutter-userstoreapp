import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/announcements/announcement_service.dart';
import '../models/in_app_announcement.dart';
import 'app_providers.dart' show apiClientProvider;

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnnouncementService(client: client);
});

final activeAnnouncementsProvider =
    FutureProvider.autoDispose<List<InAppAnnouncement>>((ref) async {
  final service = ref.watch(announcementServiceProvider);
  return service.fetchAnnouncements();
});
