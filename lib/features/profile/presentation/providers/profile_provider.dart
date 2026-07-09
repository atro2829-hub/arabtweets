import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tweets/data/models/tweet_model.dart';
import '../../../../core/constants/api_constants.dart';

// ─── Profile Notifier ─────────────────────────────────────────────────────────

class ProfileNotifier extends AsyncNotifier<UserModel> {
  final _supabase = Supabase.instance.client;
  String userId = '';

  @override
  Future<UserModel> build() async {
    return _fetchProfile(userId);
  }

  Future<UserModel> _fetchProfile(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      final response = await _supabase.rpc(
        'get_user_profile',
        params: {
          'p_user_id': userId,
          'p_viewer_id': currentUserId,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];
      if (data.isEmpty) {
        throw Exception('الملف الشخصي غير موجود');
      }
      return UserModel.fromJson(data[0] as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل الملف الشخصي: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الملف الشخصي');
    }
  }

  Future<void> toggleFollow() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final currentState = state.value;
    if (currentState == null) return;

    final wasFollowing = currentState.isFollowing;
    final newFollowersCount = wasFollowing
        ? currentState.followersCount - 1
        : currentState.followersCount + 1;

    state = AsyncData(currentState.copyWith(
      isFollowing: !wasFollowing,
      followersCount: newFollowersCount,
    ));

    try {
      await _supabase.rpc('toggle_follow', params: {
        'p_follower_id': currentUserId,
        'p_following_id': userId,
      });
    } catch (e) {
      state = AsyncData(currentState);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchProfile(userId));
  }
}

// ─── User Tweets Notifier ─────────────────────────────────────────────────────

class UserTweetsNotifier extends AsyncNotifier<List<TweetModel>> {
  final _supabase = Supabase.instance.client;
  String userId = '';

  @override
  Future<List<TweetModel>> build() async {
    return _fetchUserTweets(userId);
  }

  Future<List<TweetModel>> _fetchUserTweets(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      final response = await _supabase.rpc(
        'get_user_tweets',
        params: {
          'p_target_user_id': userId,
          'p_viewer_id': currentUserId,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];
      return data.map((item) => TweetModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

// ─── User Replies Notifier ────────────────────────────────────────────────────

class UserRepliesNotifier extends AsyncNotifier<List<TweetModel>> {
  final _supabase = Supabase.instance.client;
  String userId = '';

  @override
  Future<List<TweetModel>> build() async {
    return _fetchUserReplies(userId);
  }

  Future<List<TweetModel>> _fetchUserReplies(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    try {
      final response = await _supabase.rpc(
        'get_feed', // Reuse get_feed-like function for replies
        params: {
          'p_user_id': currentUserId,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': 0,
        },
      );

      // Fallback: fetch replies directly
      final tweetsResp = await _supabase
          .from('tweets')
          .select('''
            *,
            profiles!tweets_user_id_fkey(username, display_name, avatar_url, is_verified)
          ''')
          .eq('user_id', userId)
          .not('parent_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(ApiConstants.tweetsPerPage);

      final List<dynamic> data = tweetsResp as List<dynamic>;
      return data.map((item) {
        final tweetMap = Map<String, dynamic>.from(item as Map<String, dynamic>);
        final profile = tweetMap.remove('profiles') as Map<String, dynamic>? ?? {};
        tweetMap['username'] = profile['username'] as String? ?? '';
        tweetMap['display_name'] = profile['display_name'] as String? ?? '';
        tweetMap['avatar_url'] = profile['avatar_url'] as String? ?? '';
        tweetMap['is_verified'] = profile['is_verified'] as bool? ?? false;
        return TweetModel.fromJson(tweetMap);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

// ─── User Likes Notifier ──────────────────────────────────────────────────────

class UserLikesNotifier extends AsyncNotifier<List<TweetModel>> {
  final _supabase = Supabase.instance.client;
  String userId = '';

  @override
  Future<List<TweetModel>> build() async {
    return _fetchUserLikes(userId);
  }

  Future<List<TweetModel>> _fetchUserLikes(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_bookmarked_tweets',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];
      return data.map((item) => TweetModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

// ─── User Media Notifier ──────────────────────────────────────────────────────

class UserMediaNotifier extends AsyncNotifier<List<TweetModel>> {
  final _supabase = Supabase.instance.client;
  String userId = '';

  @override
  Future<List<TweetModel>> build() async {
    return _fetchUserMedia(userId);
  }

  Future<List<TweetModel>> _fetchUserMedia(String userId) async {
    try {
      final response = await _supabase
          .from('tweets')
          .select('''
            *,
            profiles!tweets_user_id_fkey(username, display_name, avatar_url, is_verified)
          ''')
          .eq('user_id', userId)
          .not('media_urls', 'eq', '{}')
          .order('created_at', ascending: false)
          .limit(ApiConstants.tweetsPerPage);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        final tweetMap = Map<String, dynamic>.from(item as Map<String, dynamic>);
        final profile = tweetMap.remove('profiles') as Map<String, dynamic>? ?? {};
        tweetMap['username'] = profile['username'] as String? ?? '';
        tweetMap['display_name'] = profile['display_name'] as String? ?? '';
        tweetMap['avatar_url'] = profile['avatar_url'] as String? ?? '';
        tweetMap['is_verified'] = profile['is_verified'] as bool? ?? false;
        return TweetModel.fromJson(tweetMap);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

// ─── Edit Profile State ───────────────────────────────────────────────────────

enum EditProfileStatus { initial, loading, success, error }

class EditProfileState {
  final EditProfileStatus status;
  final String? errorMessage;
  const EditProfileState({this.status = EditProfileStatus.initial, this.errorMessage});

  EditProfileState copyWith({EditProfileStatus? status, String? errorMessage, bool clearError = false}) {
    return EditProfileState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  final _supabase = Supabase.instance.client;

  @override
  EditProfileState build() => const EditProfileState();

  Future<bool> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    required String location,
    required String website,
    File? avatarFile,
    File? coverFile,
    String? currentAvatarPath,
    String? currentCoverPath,
  }) async {
    state = state.copyWith(status: EditProfileStatus.loading, clearError: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('لم يتم تسجيل الدخول');

      String avatarUrl = currentAvatarPath ?? '';
      String coverUrl = currentCoverPath ?? '';

      if (avatarFile != null) {
        final ext = avatarFile.path.split('.').last;
        final path = '$userId/avatar.$ext';
        await _supabase.storage
            .from(ApiConstants.storageBucketAvatars)
            .upload(path, avatarFile, fileOptions: const FileOptions(upsert: true));
        avatarUrl = '$path';
      }

      if (coverFile != null) {
        final ext = coverFile.path.split('.').last;
        final path = '$userId/cover.$ext';
        await _supabase.storage
            .from(ApiConstants.storageBucketCovers)
            .upload(path, coverFile, fileOptions: const FileOptions(upsert: true));
        coverUrl = '$path';
      }

      await _supabase.from('profiles').update({
        'display_name': displayName.trim(),
        'username': username.trim(),
        'bio': bio.trim(),
        'location': location.trim(),
        'website': website.trim(),
        if (avatarFile != null) 'avatar_url': avatarUrl,
        if (coverFile != null) 'cover_url': coverUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      state = state.copyWith(status: EditProfileStatus.success);
      return true;
    } on PostgrestException catch (e) {
      state = state.copyWith(status: EditProfileStatus.error, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(status: EditProfileStatus.error, errorMessage: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  void reset() => state = const EditProfileState();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final profileProvider = AsyncNotifierProvider.autoDispose.family<ProfileNotifier, UserModel, String>(
  (arg) => ProfileNotifier()..userId = arg,
);

final userTweetsProvider = AsyncNotifierProvider.autoDispose.family<UserTweetsNotifier, List<TweetModel>, String>(
  (arg) => UserTweetsNotifier()..userId = arg,
);

final userRepliesProvider = AsyncNotifierProvider.autoDispose.family<UserRepliesNotifier, List<TweetModel>, String>(
  (arg) => UserRepliesNotifier()..userId = arg,
);

final userLikesProvider = AsyncNotifierProvider.autoDispose.family<UserLikesNotifier, List<TweetModel>, String>(
  (arg) => UserLikesNotifier()..userId = arg,
);

final userMediaProvider = AsyncNotifierProvider.autoDispose.family<UserMediaNotifier, List<TweetModel>, String>(
  (arg) => UserMediaNotifier()..userId = arg,
);

final editProfileProvider = NotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>(
  EditProfileNotifier.new,
);

Future<void> toggleFollow(Ref ref, String userId) async {
  await ref.read(profileProvider(userId).notifier).toggleFollow();
}

Future<bool> updateProfile(Ref ref, {
  required String displayName,
  required String username,
  required String bio,
  required String location,
  required String website,
  File? avatarFile,
  File? coverFile,
  String? currentAvatarPath,
  String? currentCoverPath,
}) async {
  final success = await ref.read(editProfileProvider.notifier).updateProfile(
        displayName: displayName, username: username, bio: bio,
        location: location, website: website,
        avatarFile: avatarFile, coverFile: coverFile,
        currentAvatarPath: currentAvatarPath, currentCoverPath: currentCoverPath,
      );
  if (success) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) ref.invalidate(profileProvider(userId));
  }
  return success;
}