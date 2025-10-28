import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../events/providers/events_provider.dart';
import '../../events/models/event_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/user_model.dart';

/// Global search screen for finding users and events by ID
///
/// Allows searching for:
/// - Users by their unique Firebase UID
/// - Events by their unique Firestore document ID
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    var query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Введите ID или @username';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final foundUsers = <UserModel>[];
    final foundEvents = <EventModel>[];

    try {
      final profileService = ref.read(profileServiceProvider);
      
      // Check if query starts with @ (username search)
      if (query.startsWith('@')) {
        final username = query.substring(1); // Remove @
        
        // Search for exact match
        final exactUser = await profileService.getProfileByUsername(username);
        if (exactUser != null) {
          foundUsers.add(exactUser);
        }
        
        // Search for similar usernames (starting with query)
        final similarUsers = await _searchSimilarUsernames(username);
        for (final user in similarUsers) {
          if (!foundUsers.any((u) => u.id == user.id)) {
            foundUsers.add(user);
          }
        }
      } else {
        // Try to find user by ID first
        try {
          final user = await profileService.getProfile(query);
          if (user != null) {
            foundUsers.add(user);
          }
        } catch (e) {
          print('User not found by ID: $e');
        }
        
        // Also search by name containing the query
        final usersByName = await _searchUsersByName(query);
        for (final user in usersByName) {
          if (!foundUsers.any((u) => u.id == user.id)) {
            foundUsers.add(user);
          }
        }
      }
    } catch (e) {
      print('Error searching users: $e');
    }

    // Try to find events
    try {
      final eventsService = ref.read(eventsServiceProvider);
      final event = await eventsService.getEvent(query);
      
      if (event != null) {
        foundEvents.add(event);
      }
    } catch (e) {
      print('Event not found: $e');
    }

    setState(() {
      _isSearching = false;
    });

    // Navigate to results screen
    if (mounted) {
      context.push(
        '/search/results',
        extra: {
          'users': foundUsers,
          'events': foundEvents,
          'query': query,
        },
      );
      _searchController.clear();
    }
  }

  Future<List<UserModel>> _searchSimilarUsernames(String query) async {
    try {
      // This will need a Firestore query - for now return empty
      // TODO: Implement with Firestore where clause for startsWith
      return [];
    } catch (e) {
      print('Error searching similar usernames: $e');
      return [];
    }
  }

  Future<List<UserModel>> _searchUsersByName(String query) async {
    try {
      // This will need a Firestore query - for now return empty
      // TODO: Implement with Firestore where clause
      return [];
    } catch (e) {
      print('Error searching users by name: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск по ID'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Как это работает?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Введите @username или ID пользователя, либо ID события.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Username можно установить в профиле. ID можно скопировать через кнопку в профиле или событии.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '@username или ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onSubmitted: (_) => _handleSearch(),
              textInputAction: TextInputAction.search,
            ),

            const SizedBox(height: 16),

            // Search button
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Поиск...' : 'Найти'),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: AppColors.error.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Examples
            Text(
              'Примеры:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleCard(
              icon: Icons.alternate_email,
              title: 'Username',
              example: '@denol',
            ),
            const SizedBox(height: 8),
            _buildExampleCard(
              icon: Icons.person,
              title: 'ID пользователя',
              example: 'sKmDOUd60obeB7IUgueUxljGT9v2',
            ),
            const SizedBox(height: 8),
            _buildExampleCard(
              icon: Icons.event,
              title: 'ID события',
              example: 'sc4m7OU4ipTSArHR4LCv',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required IconData icon,
    required String title,
    required String example,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    example,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
