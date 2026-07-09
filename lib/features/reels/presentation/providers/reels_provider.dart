import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/reel_model.dart';

class ReelsNotifier extends AsyncNotifier<List<ReelModel>> {
  final _supabase = Supabase.instance.client;
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<ReelModel>> build() async {
    _currentOffset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchReels(offset: 0);
  }

  Future<List<ReelModel>> _fetchReels({required int offset}) async {
    final userId = _supabase.auth.currentUser?.id;
    try {
      final response = await _supabase.rpc(
        'get_reels',
        params: {
          'p_user_id': userId,
          'p_limit': 20,
          'p_offset': offset,
        },
      );
      final List<dynamic> data = response as List<dynamic>? ?? [];
      if (data.length < 20) _hasMore = false;
      return data.map((e) => ReelModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    try {
      final current = state.value ?? [];
      _currentOffset += 20;
      final newReels = await _fetchReels(offset: _currentOffset);
      state = AsyncData([...current, ...newReels]);
    } catch (e) {
      _currentOffset -= 20;
    } finally {
      _isLoadingMore = false;
    }
  }

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> toggleLike(int reelId) async {
    final currentReels = state.value;
    if (currentReels == null) return;
    final idx = currentReels.indexWhere((r) => r.id == reelId);
    if (idx == -1) return;
    final reel = currentReels[idx];
    final wasLiked = reel.isLiked;
    final newCount = wasLiked ? reel.likeCount - 1 : reel.likeCount + 1;

    final updated = List<ReelModel>.from(currentReels);
    updated[idx] = reel.copyWith(isLiked: !wasLiked, likeCount: newCount);
    state = AsyncData(updated);

    try {
      await _supabase.rpc('toggle_reel_like', params: {
        'p_user_id': _supabase.auth.currentUser!.id,
        'p_reel_id': reelId,
      });
    } catch (e) {
      final reverted = List<ReelModel>.from(currentReels);
      reverted[idx] = reel;
      state = AsyncData(reverted);
    }
  }

  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    state = AsyncData(await _fetchReels(offset: 0));
  }
}

final reelsProvider = AsyncNotifierProvider.autoDispose<ReelsNotifier, List<ReelModel>>(
  ReelsNotifier.new,
);