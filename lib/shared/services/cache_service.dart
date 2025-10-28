import 'package:hive_flutter/hive_flutter.dart';
import '../../features/events/models/event_model.dart';
import '../../features/profile/models/user_model.dart';

/// Cache service using Hive for local data persistence
///
/// Provides fast app startup by caching frequently accessed data:
/// - Recent events for quick map/feed display
/// - User profiles for offline access
/// - Blocked user IDs for event filtering
class CacheService {
  static const String _eventsBoxName = 'events_cache';
  static const String _profilesBoxName = 'profiles_cache';
  static const String _blockedUsersBoxName = 'blocked_users_cache';
  static const String _settingsBoxName = 'settings_cache';

  Box<Map>? _eventsBox;
  Box<Map>? _profilesBox;
  Box<List>? _blockedUsersBox;
  Box<dynamic>? _settingsBox;

  /// Initialize Hive and open boxes
  ///
  /// Call this once at app startup before using any cache methods.
  Future<void> initialize() async {
    await Hive.initFlutter();

    _eventsBox = await Hive.openBox<Map>(_eventsBoxName);
    _profilesBox = await Hive.openBox<Map>(_profilesBoxName);
    _blockedUsersBox = await Hive.openBox<List>(_blockedUsersBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Close all boxes (call on app dispose)
  Future<void> dispose() async {
    await _eventsBox?.close();
    await _profilesBox?.close();
    await _blockedUsersBox?.close();
    await _settingsBox?.close();
  }

  // ============================================================
  // Events Cache
  // ============================================================

  /// Cache a list of events
  ///
  /// Stores events by location key for quick retrieval.
  /// Location key format: "lat_lng" (e.g., "55.7558_37.6173")
  Future<void> cacheEvents(List<EventModel> events, String locationKey) async {
    if (_eventsBox == null) throw Exception('Cache not initialized');

    final eventsJson = events.map((e) => e.toJson()).toList();
    await _eventsBox!.put(locationKey, {
      'events': eventsJson,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get cached events for location
  ///
  /// Returns null if no cache exists or cache is older than [maxAge].
  /// Default maxAge is 5 minutes.
  List<EventModel>? getCachedEvents(
    String locationKey, {
    Duration maxAge = const Duration(minutes: 5),
  }) {
    if (_eventsBox == null) return null;

    final data = _eventsBox!.get(locationKey);
    if (data == null) return null;

    // Check cache age
    final cachedAt = DateTime.parse(data['cachedAt'] as String);
    if (DateTime.now().difference(cachedAt) > maxAge) {
      // Cache expired
      return null;
    }

    final eventsJson = data['events'] as List;
    return eventsJson
        .map((json) => EventModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Clear all cached events
  Future<void> clearEventsCache() async {
    await _eventsBox?.clear();
  }

  // ============================================================
  // Profiles Cache
  // ============================================================

  /// Cache a user profile
  Future<void> cacheProfile(UserModel profile) async {
    if (_profilesBox == null) throw Exception('Cache not initialized');

    await _profilesBox!.put(profile.id, {
      'profile': profile.toJson(),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get cached profile
  ///
  /// Returns null if no cache exists or cache is older than [maxAge].
  /// Default maxAge is 10 minutes.
  UserModel? getCachedProfile(
    String userId, {
    Duration maxAge = const Duration(minutes: 10),
  }) {
    if (_profilesBox == null) return null;

    final data = _profilesBox!.get(userId);
    if (data == null) return null;

    // Check cache age
    final cachedAt = DateTime.parse(data['cachedAt'] as String);
    if (DateTime.now().difference(cachedAt) > maxAge) {
      return null;
    }

    return UserModel.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
  }

  /// Cache multiple profiles at once
  Future<void> cacheProfiles(List<UserModel> profiles) async {
    if (_profilesBox == null) throw Exception('Cache not initialized');

    for (final profile in profiles) {
      await cacheProfile(profile);
    }
  }

  /// Clear all cached profiles
  Future<void> clearProfilesCache() async {
    await _profilesBox?.clear();
  }

  // ============================================================
  // Blocked Users Cache
  // ============================================================

  /// Cache blocked user IDs
  ///
  /// Used for filtering events without network call.
  Future<void> cacheBlockedUsers(List<String> blockedUserIds) async {
    if (_blockedUsersBox == null) throw Exception('Cache not initialized');

    await _blockedUsersBox!.put('blocked_users', blockedUserIds);
  }

  /// Get cached blocked user IDs
  ///
  /// Returns empty list if no cache exists.
  List<String> getCachedBlockedUsers() {
    if (_blockedUsersBox == null) return [];

    final blocked = _blockedUsersBox!.get('blocked_users');
    if (blocked == null) return [];

    return List<String>.from(blocked);
  }

  /// Add a user to blocked cache
  Future<void> addBlockedUser(String userId) async {
    final blocked = getCachedBlockedUsers();
    if (!blocked.contains(userId)) {
      blocked.add(userId);
      await cacheBlockedUsers(blocked);
    }
  }

  /// Remove a user from blocked cache
  Future<void> removeBlockedUser(String userId) async {
    final blocked = getCachedBlockedUsers();
    blocked.remove(userId);
    await cacheBlockedUsers(blocked);
  }

  /// Clear blocked users cache
  Future<void> clearBlockedUsersCache() async {
    await _blockedUsersBox?.delete('blocked_users');
  }

  // ============================================================
  // Settings Cache
  // ============================================================

  /// Save a setting value
  Future<void> saveSetting(String key, dynamic value) async {
    if (_settingsBox == null) throw Exception('Cache not initialized');
    await _settingsBox!.put(key, value);
  }

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (_settingsBox == null) return defaultValue;
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  /// Clear all caches
  Future<void> clearAll() async {
    await clearEventsCache();
    await clearProfilesCache();
    await clearBlockedUsersCache();
    await clearSettings();
  }

  /// Get total cache size info
  Map<String, int> getCacheInfo() {
    return {
      'events': _eventsBox?.length ?? 0,
      'profiles': _profilesBox?.length ?? 0,
      'blockedUsers': getCachedBlockedUsers().length,
      'settings': _settingsBox?.length ?? 0,
    };
  }
}
