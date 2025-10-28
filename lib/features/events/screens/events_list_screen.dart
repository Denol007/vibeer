import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/category_selector.dart';
import '../models/event_category.dart';
import '../models/event_model.dart';
import 'package:geolocator/geolocator.dart';

/// Events list screen showing all active events
///
/// Displays vertical list of event cards sorted by start time.
/// Alternative view to map screen.
class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  Position? _currentPosition;
  bool _isLoadingPosition = true;
  Set<EventCategory> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  void _onCategoryToggled(EventCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingPosition = false;
      });
    } catch (e) {
      // Use default location (Moscow) if can't get position
      setState(() {
        _currentPosition = Position(
          latitude: 55.7558,
          longitude: 37.6173,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _isLoadingPosition = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPosition) {
      return const Scaffold(appBar: null, body: LoadingIndicator());
    }

    final eventsService = ref.watch(eventsServiceProvider);
    final center = GeoPoint(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Все события'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Поиск по ID',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/event/create'),
            tooltip: 'Создать событие',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: eventsService.getActiveEventsInBounds(
          center: center,
          radiusKm: 10.0, // Larger radius for list view
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          // Apply category filter
          final filteredEvents = _selectedCategories.isEmpty
              ? events
              : events
                  .where((event) => _selectedCategories.contains(event.category))
                  .toList();

          if (filteredEvents.isEmpty) {
            return Column(
              children: [
                // Category filter chips
                CategoryChipSelector(
                  selectedCategories: _selectedCategories,
                  onCategoryToggled: _onCategoryToggled,
                  showAllOption: true,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategories.isEmpty
                              ? 'Нет событий поблизости'
                              : 'Нет событий в выбранных категориях',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте первое событие!',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/event/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Создать событие'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Sort events by start time
          final sortedEvents = List<EventModel>.from(filteredEvents)
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              // Category filter chips
              CategoryChipSelector(
                selectedCategories: _selectedCategories,
                onCategoryToggled: _onCategoryToggled,
                showAllOption: true,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh is handled automatically by stream
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedEvents.length,
                    itemBuilder: (context, index) {
                      final event = sortedEvents[index];
                      return EventCard(
                        event: event,
                        userPosition: _currentPosition,
                        onTap: () => context.push('/home/event/${event.id}'),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
