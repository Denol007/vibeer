import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../providers/events_provider.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';

enum SortOption { time, distance }

/// Event feed screen displaying events as a list
///
/// Alternative view to map screen with sorting options.
/// Shows events in vertical list with pull-to-refresh.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  List<EventModel> _events = [];
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  SortOption _sortOption = SortOption.time;
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  static const LatLng _defaultLocation = LatLng(55.7558, 37.6173);
  static const double _searchRadiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          _currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
        }
      }

      // Load events
      final location = _currentPosition != null
          ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
          : GeoPoint(_defaultLocation.latitude, _defaultLocation.longitude);

      _eventsSubscription?.cancel();
      final eventsService = ref.read(eventsServiceProvider);

      _eventsSubscription = eventsService
          .getActiveEventsInBounds(center: location, radiusKm: _searchRadiusKm)
          .listen(
            (events) {
              setState(() {
                _events = events;
                _sortEvents();
                _isLoading = false;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = 'Ошибка загрузки событий';
                _isLoading = false;
              });
            },
          );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки событий';
        _isLoading = false;
      });
    }
  }

  void _sortEvents() {
    if (_sortOption == SortOption.time) {
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else if (_sortOption == SortOption.distance && _currentPosition != null) {
      _events.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distA.compareTo(distB);
      });
    }
  }

  void _changeSortOption(SortOption? option) {
    if (option != null && option != _sortOption) {
      setState(() {
        _sortOption = option;
        _sortEvents();
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadEvents();
  }

  void _onEventTapped(EventModel event) {
    // Navigate to event detail screen (T051)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Event: ${event.title}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('События'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // Navigate back to map screen
              Navigator.of(context).pop();
            },
            tooltip: 'Карта',
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: _changeSortOption,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.time,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: _sortOption == SortOption.time
                          ? AppColors.primary
                          : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'По времени',
                      style: TextStyle(
                        color: _sortOption == SortOption.time
                            ? AppColors.primary
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.distance,
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 20,
                      color: _sortOption == SortOption.distance
                          ? AppColors.primary
                          : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'По расстоянию',
                      style: TextStyle(
                        color: _sortOption == SortOption.distance
                            ? AppColors.primary
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEvents,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : _events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет событий поблизости',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return EventCard(
                    event: event,
                    userPosition: _currentPosition,
                    onTap: () => _onEventTapped(event),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create event screen (T049)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Создание события - скоро')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
