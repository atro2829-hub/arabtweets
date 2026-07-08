import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../notifications/data/models/notification_model.dart';
import '../../../../core/constants/api_constants.dart';

// ─── Notifications Notifier ────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<NotificationModel>> build() async {
    return _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_user_notifications',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.notificationsPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      return data
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل الإشعارات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الإشعارات');
    }
  }

  /// Mark all notifications as read for the current user.
  Future<void> markAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.rpc('mark_notifications_read', params: {
        'p_user_id': userId,
      });

      // Update local state: mark all as read
      final current = state.value;
      if (current != null) {
        final updated = current
            .map((n) => NotificationModel(
                  id: n.id,
                  fromUserId: n.fromUserId,
                  type: n.type,
                  tweetId: n.tweetId,
                  isRead: true,
                  createdAt: n.createdAt,
                  fromUsername: n.fromUsername,
                  fromDisplayName: n.fromDisplayName,
                  fromAvatarUrl: n.fromAvatarUrl,
                  tweetContent: n.tweetContent,
                ))
            .toList();
        state = AsyncData(updated);
      }
    } catch (e) {
      // Silently fail for mark-as-read
    }
  }

  /// Refresh notifications list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchNotifications());
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// Primary notifications provider.
final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

/// Derived provider: count of unread notifications.
final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final notifications = notificationsAsync.value ?? [];
  return notifications.where((n) => !n.isRead).length;
});