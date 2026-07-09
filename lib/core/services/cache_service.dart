import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton cache service for offline data persistence.
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();
  CacheService._();

  static const _p = 'at_cache_';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _db async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Generic Save/Get ─────────────────────────────────────────────

  Future<void> save(String key, List<Map<String, dynamic>> data) async {
    final db = await _db;
    await db.setString('$_p$key', jsonEncode(data));
    await db.setInt('${_p}sync_$key', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>> get(String key) async {
    final db = await _db;
    final raw = db.getString('$_p$key');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveStringList(String key, List<String> data) async {
    final db = await _db;
    await db.setString('$_p$key', jsonEncode(data));
  }

  Future<List<String>> getStringList(String key) async {
    final db = await _db;
    final raw = db.getString('$_p$key');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  // ─── Specific Keys ───────────────────────────────────────────────

  Future<void> saveFeed(List<Map<String, dynamic>> tweets) => save('feed', tweets);
  Future<List<Map<String, dynamic>>> getFeed() => get('feed');

  Future<void> saveNotifications(List<Map<String, dynamic>> notifs) => save('notifs', notifs);
  Future<List<Map<String, dynamic>>> getNotifications() => get('notifs');

  Future<void> saveConversations(List<Map<String, dynamic>> convos) => save('convos', convos);
  Future<List<Map<String, dynamic>>> getConversations() => get('convos');

  Future<void> saveProfile(String userId, Map<String, dynamic> profile) async {
    final db = await _db;
    await db.setString('${_p}prof_$userId', jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await _db;
    final raw = db.getString('${_p}prof_$userId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSearchHistory(List<String> queries) => saveStringList('search', queries);
  Future<List<String>> getSearchHistory() => getStringList('search');

  Future<void> addSearchQuery(String query) async {
    final h = await getSearchHistory();
    h.remove(query);
    h.insert(0, query);
    if (h.length > 20) h.removeRange(20, h.length);
    await saveSearchHistory(h);
  }

  Future<void> clearSearchHistory() async {
    final db = await _db;
    await db.remove('${_p}search');
  }

  // ─── Freshness & Connectivity ─────────────────────────────────────

  Future<bool> isCacheFresh(String key, {Duration maxAge = const Duration(minutes: 5)}) async {
    final db = await _db;
    final ms = db.getInt('${_p}sync_$key');
    if (ms == null) return false;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms)) < maxAge;
  }

  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((c) => c != ConnectivityResult.none);
  }

  Future<void> clearAll() async {
    final db = await _db;
    final keys = db.getKeys().where((k) => k.startsWith(_p)).toList();
    for (final key in keys) await db.remove(key);
  }
}