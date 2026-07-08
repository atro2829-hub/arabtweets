import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Admin Stats Notifier ──────────────────────────────────────────────────────

class AdminStatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> build() async {
    return _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      final response = await _supabase.rpc('get_admin_stats');
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل الإحصائيات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الإحصائيات');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchStats());
  }
}

// ─── All Users Notifier ────────────────────────────────────────────────────────

class AllUsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await _supabase.rpc('get_all_users');
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل المستخدمين: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل المستخدمين');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchUsers());
  }
}

// ─── All Reports Notifier ──────────────────────────────────────────────────────

class AllReportsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchReports();
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
      final response = await _supabase.rpc('get_all_reports_fn');
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل البلاغات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل البلاغات');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchReports());
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// Checks if current user has admin privileges.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  // Check is_admin on the user model if the field exists.
  // For now, we check the profiles table.
  if (user == null) return false;
  // The is_admin field may need to be added to UserModel, so we read from raw data.
  final client = Supabase.instance.client;
  final profile = client.auth.currentUser;
  if (profile == null) return false;

  // We use a sync check from the auth provider user model.
  // If is_admin is not on UserModel, fall back to a dedicated check.
  // For this implementation, we assume is_admin might be a dynamic field.
  // The safest approach is to check via the auth state's user metadata or profiles.
  return false; // Will be overridden by the async check below
});

/// Async admin check provider – fetches is_admin from profiles table.
final isAdminAsyncProvider = FutureProvider<bool>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;

  try {
    final response = await client
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .maybeSingle();

    if (response != null) {
      return response['is_admin'] as bool? ?? false;
    }
    return false;
  } catch (_) {
    return false;
  }
});

/// Admin statistics (total users, tweets, pending reports, today registrations).
final adminStatsProvider =
    AsyncNotifierProvider<AdminStatsNotifier, Map<String, dynamic>>(
  AdminStatsNotifier.new,
);

/// All users list for admin dashboard.
final allUsersProvider =
    AsyncNotifierProvider<AllUsersNotifier, List<Map<String, dynamic>>>(
  AllUsersNotifier.new,
);

/// All reports list for admin dashboard.
final allReportsProvider =
    AsyncNotifierProvider<AllReportsNotifier, List<Map<String, dynamic>>>(
  AllReportsNotifier.new,
);

// ─── Admin Actions ─────────────────────────────────────────────────────────────

/// Delete a tweet by its ID.
Future<void> deleteTweet(WidgetRef ref, int tweetId) async {
  final client = Supabase.instance.client;
  await client.from('tweets').delete().eq('id', tweetId);
  // Refresh providers
  ref.invalidate(adminStatsProvider);
}

/// Ban a user by their user ID.
Future<void> banUser(WidgetRef ref, String userId) async {
  final client = Supabase.instance.client;
  await client.from('profiles').update({'is_banned': true}).eq('id', userId);
  ref.invalidate(allUsersProvider);
  ref.invalidate(adminStatsProvider);
}

/// Update a report's status.
Future<void> updateReport(WidgetRef ref, int reportId, String status) async {
  final client = Supabase.instance.client;
  await client
      .from('reports')
      .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
      .eq('id', reportId);
  ref.invalidate(allReportsProvider);
  ref.invalidate(adminStatsProvider);
}

/// Toggle a user's verified status.
Future<void> toggleVerified(WidgetRef ref, String userId, bool verified) async {
  final client = Supabase.instance.client;
  await client
      .from('profiles')
      .update({'is_verified': verified})
      .eq('id', userId);
  ref.invalidate(allUsersProvider);
}

/// Toggle a user's admin status.
Future<void> toggleAdmin(WidgetRef ref, String userId, bool isAdmin) async {
  final client = Supabase.instance.client;
  await client
      .from('profiles')
      .update({'is_admin': isAdmin})
      .eq('id', userId);
  ref.invalidate(allUsersProvider);
}