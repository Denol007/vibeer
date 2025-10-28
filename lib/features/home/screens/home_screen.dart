import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/screens/map_screen.dart';
import '../../events/screens/events_list_screen.dart';
import '../../events/screens/my_events_screen.dart';
import '../../chat/screens/conversations_list_screen.dart';
import '../../chat/providers/chat_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';

/// Main home screen with bottom navigation
///
/// Container for main app screens with bottom navigation bar:
/// - Map: Events on map
/// - Events: List of all events
/// - My Events: User's created/joined events
/// - Chats: Private conversations
/// - Profile: User profile and settings
class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final conversationsStream = ref.watch(userConversationsStreamProvider);
    
    // Calculate total unread count
    int totalUnreadCount = 0;
    conversationsStream.whenData((conversations) {
      if (currentUser != null) {
        totalUnreadCount = conversations.fold<int>(
          0,
          (sum, conv) => sum + conv.getUnreadCount(currentUser.id),
        );
      }
    });

    // Screens for each tab
    final screens = [
      const MapScreen(),
      const EventsListScreen(),
      const MyEventsScreen(),
      const ConversationsListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Карта'),
          const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'События'),
          const BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Мои'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble),
                if (totalUnreadCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalUnreadCount > 99 ? '99+' : totalUnreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Чаты',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
