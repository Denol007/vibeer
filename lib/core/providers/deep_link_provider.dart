import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/deep_link_service.dart';

/// Provider for deep link service
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  
  // Initialize on creation
  service.initialize();
  
  // Dispose on cleanup
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for deep link stream
final deepLinkStreamProvider = StreamProvider<Uri>((ref) {
  final deepLinkService = ref.watch(deepLinkServiceProvider);
  return deepLinkService.linkStream;
});
