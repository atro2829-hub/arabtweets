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
      // Fetch profile with counts
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profileMap = Map<String, dynamic>.from(profileResponse);

      // Fetch counts
      final tweetsCount = await _supabase
          .from('tweets')
          .select('id')
          .eq('user_id', userId)
          .filter('parent_id', 'is', null);

      final followersCount = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      final followingCount = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      profileMap['followers_count'] = (followersCount as List).length;
      profileMap['following_count'] = (followingCount as List).length;
      profileMap['tweets_count'] = (tweetsCount as List).length;

      // Check if current user follows this profile
      if (currentUserId != null && currentUserId != userId) {
        final followCheck = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();

        profileMap['is_following'] = followCheck != null;
      } else {
        profileMap['is_following'] = false;
      }

      return UserModel.fromJson(profileMap);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل الملف الشخصي: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الملف الشخصي');
    }
  }

  /// Toggle follow status for this profile.
  Future<void> toggleFollow() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final currentState = state.value;
    if (currentState == null) return;

    final wasFollowing = currentState.isFollowing;
    final newFollowersCount = wasFollowing
        ? currentState.followersCount - 1
        : currentState.followersCount + 1;

    // Optimistic update
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
      // Revert on error
      state = AsyncData(currentState);
    }
  }

  /// Refresh profile data.
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
      final response = await _supabase
          .from('tweets')
          .select('''
            *,
            profiles!tweets_user_id_fkey(
              username,
              display_name,
              avatar_url,
              is_verified
            )
          ''')
          .eq('user_id', userId)
          .filter('parent_id', 'is', null)
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

        if (currentUserId != null) {
          tweetMap['is_liked'] = false;
          tweetMap['is_retweeted'] = false;
          tweetMap['is_bookmarked'] = false;
        }

        return TweetModel.fromJson(tweetMap);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل التغريدات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل التغريدات');
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
    try {
      final response = await _supabase
          .from('tweets')
          .select('''
            *,
            profiles!tweets_user_id_fkey(
              username,
              display_name,
              avatar_url,
              is_verified
            )
          ''')
          .eq('user_id', userId)
          .not('parent_id', 'is', null)
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
      final response = await _supabase
          .from('likes')
          .select('''
            tweet_id,
            tweets (
              id,
              user_id,
              content,
              media_urls,
              reply_count,
              retweet_count,
              like_count,
              view_count,
              bookmark_count,
              created_at,
              profiles!tweets_user_id_fkey (
                username,
                display_name,
                avatar_url,
                is_verified
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(ApiConstants.tweetsPerPage);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((item) {
        final likeMap = item as Map<String, dynamic>;
        final tweet = likeMap['tweets'] as Map<String, dynamic>;
        final profile =
            tweet.remove('profiles') as Map<String, dynamic>? ?? {};
        tweet['username'] = profile['username'] as String? ?? '';
        tweet['display_name'] = profile['display_name'] as String? ?? '';
        tweet['avatar_url'] = profile['avatar_url'] as String? ?? '';
        tweet['is_verified'] = profile['is_verified'] as bool? ?? false;
        tweet['is_liked'] = true;
        return TweetModel.fromJson(tweet);
      }).toList();
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
            profiles!tweets_user_id_fkey(
              username,
              display_name,
              avatar_url,
              is_verified
            )
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

  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.errorMessage,
  });

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  final _supabase = Supabase.instance.client;

  @override
  EditProfileState build() {
    return const EditProfileState();
  }

  /// Update profile text fields and optionally upload new images.
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
      if (userId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      String avatarUrl = currentAvatarPath ?? '';
      String coverUrl = currentCoverPath ?? '';

      // Upload avatar if changed
      if (avatarFile != null) {
        final ext = avatarFile.path.split('.').last;
        final path = '$userId/avatar.$ext';
        await _supabase.storage
            .from(ApiConstants.storageBucketAvatars)
            .upload(path, avatarFile, fileOptions: const FileOptions(upsert: true));
        avatarUrl = '${ApiConstants.storageBucketAvatars}/$path';
      }

      // Upload cover if changed
      if (coverFile != null) {
        final ext = coverFile.path.split('.').last;
        final path = '$userId/cover.$ext';
        await _supabase.storage
            .from(ApiConstants.storageBucketCovers)
            .upload(path, coverFile, fileOptions: const FileOptions(upsert: true));
        coverUrl = '${ApiConstants.storageBucketCovers}/$path';
      }

      // Update profile
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
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: e.message,
      );
      return false;
    } on StorageException catch (e) {
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: 'فشل في رفع الصورة: ${e.message}',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: 'حدث خطأ غير متوقع أثناء تحديث الملف الشخصي',
      );
      return false;
    }
  }

  void reset() {
    state = const EditProfileState();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Loads a user profile with counts and follow status.
final profileProvider = AsyncNotifierProvider.autoDispose.family<
    ProfileNotifier, UserModel, String>(
  (arg) => ProfileNotifier()..userId = arg,
);

/// Loads user's tweets (no replies).
final userTweetsProvider = AsyncNotifierProvider.autoDispose.family<
    UserTweetsNotifier, List<TweetModel>, String>(
  (arg) => UserTweetsNotifier()..userId = arg,
);

/// Loads user's replies.
final userRepliesProvider = AsyncNotifierProvider.autoDispose.family<
    UserRepliesNotifier, List<TweetModel>, String>(
  (arg) => UserRepliesNotifier()..userId = arg,
);

/// Loads user's liked tweets.
final userLikesProvider = AsyncNotifierProvider.autoDispose.family<
    UserLikesNotifier, List<TweetModel>, String>(
  (arg) => UserLikesNotifier()..userId = arg,
);

/// Loads user's media tweets.
final userMediaProvider = AsyncNotifierProvider.autoDispose.family<
    UserMediaNotifier, List<TweetModel>, String>(
  (arg) => UserMediaNotifier()..userId = arg,
);

/// Edit profile state notifier.
final editProfileProvider =
    NotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>(
  EditProfileNotifier.new,
);

/// Convenience function: toggle follow on a user by userId.
/// This invalidates the profileProvider for that user so it re-fetches.
Future<void> toggleFollow(Ref ref, String userId) async {
  final notifier = ref.read(profileProvider(userId).notifier);
  await notifier.toggleFollow();
}

/// Convenience function: update profile data.
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
        displayName: displayName,
        username: username,
        bio: bio,
        location: location,
        website: website,
        avatarFile: avatarFile,
        coverFile: coverFile,
        currentAvatarPath: currentAvatarPath,
        currentCoverPath: currentCoverPath,
      );

  if (success) {
    // Invalidate profile so it re-fetches
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ref.invalidate(profileProvider(userId));
    }
  }

  return success;
}