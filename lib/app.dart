import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/services/deep_link_service.dart';

/// Root application widget with deep link handling
class VibeApp extends ConsumerStatefulWidget {
  const VibeApp({super.key});

  @override
  ConsumerState<VibeApp> createState() => _VibeAppState();
}

class _VibeAppState extends ConsumerState<VibeApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final currentThemeMode = ref.watch(themeProvider);
    
    // Listen to deep links within build method
    ref.listen<AsyncValue<Uri>>(
      deepLinkStreamProvider,
      (previous, next) {
        next.whenData((uri) {
          print('🔗 Handling deep link: $uri');
          
          final deepLinkService = ref.read(deepLinkServiceProvider);
          final route = deepLinkService.parseDeepLink(uri);

          if (route == null) {
            print('⚠️ Could not parse deep link');
            return;
          }

          // Navigate based on deep link type
          switch (route.type) {
            case DeepLinkType.event:
              print('📍 Navigating to event: ${route.id}');
              router.push('/home/event/${route.id}');
              break;
            
            case DeepLinkType.userProfile:
              print('👤 Navigating to user profile: ${route.id}');
              router.push('/user/${route.id}');
              break;
          }
        });
      },
    );

    // Convert AppThemeMode to ThemeMode
    final themeMode = switch (currentThemeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: 'Vibe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
