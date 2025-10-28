import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';

/// Provider for cache service singleton
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
