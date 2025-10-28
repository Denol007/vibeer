import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';

/// My events screen showing user's created and joined events
///
/// Displays two tabs:
/// - Organized: Events created by current user
/// - Joined: Events user has joined as participant
class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои события'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Организованные'),
            Tab(text: 'Участвую'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/event/create'),
            tooltip: 'Создать событие',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrganizedEvents(), _buildJoinedEvents()],
      ),
    );
  }

  Widget _buildOrganizedEvents() {
    final eventsService = ref.watch(eventsServiceProvider);

    return StreamBuilder(
      stream: eventsService.getMyOrganizedEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Вы еще не создали событий',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/event/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать первое событие'),
                ),
              ],
            ),
          );
        }

        // Sort by start time
        final sortedEvents = List.from(events)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedEvents.length,
          itemBuilder: (context, index) {
            final event = sortedEvents[index];
            return EventCard(
              event: event,
              onTap: () => context.push('/home/event/${event.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildJoinedEvents() {
    final eventsService = ref.watch(eventsServiceProvider);

    return StreamBuilder(
      stream: eventsService.getMyParticipatingEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Вы еще не присоединились к событиям',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Найдите интересные события на карте!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Sort by start time
        final sortedEvents = List.from(events)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedEvents.length,
          itemBuilder: (context, index) {
            final event = sortedEvents[index];
            return EventCard(
              event: event,
              onTap: () => context.push('/home/event/${event.id}'),
            );
          },
        );
      },
    );
  }
}
