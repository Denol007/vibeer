import 'dart:async';
import 'package:app_links/app_links.dart';

/// Service for handling deep links and generating shareable links
///
/// Supports formats:
/// - vibe://event/{eventId} - Open event details
/// - vibe://user/{userId} - Open user profile
class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  
  /// Stream controller for incoming deep links
  final _deepLinkController = StreamController<Uri>.broadcast();
  
  /// Stream of incoming deep links
  Stream<Uri> get linkStream => _deepLinkController.stream;
  
  /// Initialize deep link listening
  Future<void> initialize() async {
    try {
      // Check if app was opened with a deep link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _deepLinkController.add(initialLink);
        print('🔗 Initial deep link: $initialLink');
      }
    } catch (e) {
      print('❌ Failed to get initial link: $e');
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _deepLinkController.add(uri);
        print('🔗 Incoming deep link: $uri');
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );
  }

  /// Generate shareable link for an event
  String generateEventLink(String eventId) {
    return 'vibe://event/$eventId';
  }

  /// Generate shareable link for a user profile
  String generateUserProfileLink(String userId) {
    return 'vibe://user/$userId';
  }

  /// Parse deep link and extract route information
  /// Supports both vibe:// and https://vibe.app/ schemes
  DeepLinkRoute? parseDeepLink(Uri uri) {
    // Support both custom scheme (vibe://) and HTTPS (https://vibe.app)
    if (uri.scheme != 'vibe' && !(uri.scheme == 'https' && uri.host == 'vibe.app')) {
      print('⚠️ Invalid scheme or host: ${uri.scheme}://${uri.host}');
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      print('⚠️ Empty path segments');
      return null;
    }

    final type = segments[0];
    
    switch (type) {
      case 'event':
        if (segments.length < 2) return null;
        return DeepLinkRoute(
          type: DeepLinkType.event,
          id: segments[1],
        );
      
      case 'user':
        if (segments.length < 2) return null;
        return DeepLinkRoute(
          type: DeepLinkType.userProfile,
          id: segments[1],
        );
      
      default:
        print('⚠️ Unknown deep link type: $type');
        return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}

/// Types of deep links supported
enum DeepLinkType {
  event,
  userProfile,
}

/// Parsed deep link route information
class DeepLinkRoute {
  final DeepLinkType type;
  final String id;
  final Map<String, String>? queryParams;

  DeepLinkRoute({
    required this.type,
    required this.id,
    this.queryParams,
  });

  @override
  String toString() => 'DeepLinkRoute(type: $type, id: $id)';
}
