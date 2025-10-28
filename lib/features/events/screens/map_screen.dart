import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/events_provider.dart';
import '../models/event_model.dart';
import '../models/event_category.dart';
import '../widgets/event_map_marker.dart';
import '../widgets/category_selector.dart';
import '../../notifications/providers/notification_provider.dart';

/// Main map screen displaying events as markers
///
/// Shows Google Map centered on user's location with event markers.
/// Users can tap markers to view event details and create new events via FAB.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<EventModel>>? _eventsSubscription;
  
  // Category filter state
  Set<EventCategory> _selectedCategories = {};
  List<EventModel> _allEvents = [];

  // Default location (Moscow) if location access fails
  static const LatLng _defaultLocation = LatLng(55.7558, 37.6173);
  static const double _defaultZoom = 14.0;

  // Radius filter options
  double? _selectedRadiusKm = 5.0; // null = show all events
  static const List<double?> _radiusOptions = [
    null,
    1.0,
    5.0,
    10.0,
    25.0,
    50.0,
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Включите службы геолокации';
          _isLoading = false;
        });
        _loadEventsForLocation(_defaultLocation);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Разрешите доступ к местоположению';
            _isLoading = false;
          });
          _loadEventsForLocation(_defaultLocation);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Доступ к местоположению запрещен. Измените настройки.';
          _isLoading = false;
        });
        _loadEventsForLocation(_defaultLocation);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to user location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            _defaultZoom,
          ),
        );
      }

      // Load events near user location
      _loadEventsForLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка получения местоположения';
        _isLoading = false;
      });
      _loadEventsForLocation(_defaultLocation);
    }
  }

  void _loadEventsForLocation(LatLng location) {
    // Cancel previous subscription
    _eventsSubscription?.cancel();

    final eventsService = ref.read(eventsServiceProvider);
    final center = GeoPoint(location.latitude, location.longitude);

    print(
      '🗺️ Loading events near: ${location.latitude}, ${location.longitude}, radius: ${_selectedRadiusKm ?? "ALL"} km',
    );

    // Use large radius for "all events", but not too large to avoid errors
    final radiusToUse = _selectedRadiusKm ?? 100.0; // 100km for "show all"

    _eventsSubscription = eventsService
        .getActiveEventsInBounds(center: center, radiusKm: radiusToUse)
        .listen(
          (events) {
            print('📍 Received ${events.length} events from service');
            for (final event in events) {
              print(
                '  - ${event.title} at ${event.location.latitude}, ${event.location.longitude}',
              );
            }
            setState(() {
              _allEvents = events;
              _errorMessage = null; // Clear any previous errors
              _isLoading = false;
            });
            _applyFiltersAndUpdateMarkers();
          },
          onError: (error, stackTrace) {
            print('❌ Error loading events: $error');
            print('📚 Error type: ${error.runtimeType}');
            print('Stack trace: $stackTrace');
            
            // Check if this is an index error (common when indexes not created)
            final errorString = error.toString().toLowerCase();
            if (errorString.contains('index') || errorString.contains('requires an index')) {
              print('⚠️ Firestore index missing - events may not load until indexes are created');
              // Don't show error for missing indexes if events already loaded
              if (_allEvents.isEmpty) {
                setState(() {
                  _errorMessage = 'Необходимо создать индексы в Firebase Console';
                  _isLoading = false;
                });
              }
              return;
            }
            
            // Don't show error if we already have events loaded
            if (_allEvents.isEmpty) {
              setState(() {
                _errorMessage = 'Ошибка загрузки событий';
                _isLoading = false;
              });
            } else {
              print('⚠️ Error occurred but keeping existing ${_allEvents.length} events');
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
  }

  Future<void> _applyFiltersAndUpdateMarkers() async {
    // Apply category filter
    final filteredEvents = _selectedCategories.isEmpty
        ? _allEvents
        : _allEvents
            .where((event) => _selectedCategories.contains(event.category))
            .toList();

    print(
      '🔍 Filtered ${_allEvents.length} events → ${filteredEvents.length} (categories: ${_selectedCategories.map((c) => c.displayName).join(", ")})',
    );

    final newMarkers = <Marker>{};

    // Create markers asynchronously with custom icons
    for (final event in filteredEvents) {
      final marker = await EventMapMarker.createMarker(
        event: event,
        onTap: () => _onMarkerTapped(event),
      );
      newMarkers.add(marker);
    }

    print('🎯 Updated ${newMarkers.length} markers on map');

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _onCategoryToggled(EventCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    _applyFiltersAndUpdateMarkers();
  }

  void _onMarkerTapped(EventModel event) {
    // Navigate to event detail screen
    context.push('/home/event/${event.id}');
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Apply dark theme to map if needed
    await _applyMapTheme(controller);

    // Move to user location if available
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _defaultZoom,
        ),
      );
    }
  }

  /// Apply map theme based on current app theme
  Future<void> _applyMapTheme(GoogleMapController controller) async {
    final themeMode = ref.read(themeProvider);
    final brightness = Theme.of(context).brightness;
    
    // Determine if dark mode is active
    bool isDark = false;
    if (themeMode == AppThemeMode.dark) {
      isDark = true;
    } else if (themeMode == AppThemeMode.system) {
      isDark = brightness == Brightness.dark;
    }

    if (isDark) {
      try {
        final String style = await rootBundle.loadString(
          'assets/map_styles/dark_map_style.json',
        );
        await controller.setMapStyle(style);
        print('🗺️ Applied dark map style');
      } catch (e) {
        print('❌ Error loading dark map style: $e');
      }
    } else {
      // Reset to default light style
      await controller.setMapStyle(null);
      print('🗺️ Applied light map style');
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Optionally reload events when map moves significantly
    // For MVP, we'll load once based on initial location
  }

  void _onCreateEventPressed() {
    // Navigate to create event screen
    context.push('/event/create');
  }

  Future<void> _showRadiusFilterDialog() async {
    final selectedRadius = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр радиуса'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _radiusOptions.map((radius) {
            final isSelected = radius == _selectedRadiusKm;
            final label = radius == null
                ? 'Все события'
                : '${radius.toInt()} км';

            return RadioListTile<double?>(
              title: Text(label),
              value: radius,
              groupValue: _selectedRadiusKm,
              selected: isSelected,
              activeColor: AppColors.primary,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedRadiusKm),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (selectedRadius != _selectedRadiusKm && mounted) {
      setState(() {
        _selectedRadiusKm = selectedRadius;
      });

      // Reload events with new radius
      final location = _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : _defaultLocation;
      _loadEventsForLocation(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    // Listen to theme changes and update map style
    ref.listen<AppThemeMode>(themeProvider, (previous, next) {
      if (previous != null && previous != next && _mapController != null) {
        print('🎨 Theme changed from $previous to $next, updating map style');
        _applyMapTheme(_mapController!);
      }
    });

    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: unreadCountAsync.when(
          data: (unreadCount) => IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Уведомления',
          ),
          loading: () => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Уведомления',
          ),
          error: (_, __) => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Уведомления',
          ),
        ),
        title: const Text('Карта событий'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Поиск по @username или ID',
          ),
          // Radius filter button
          IconButton(
            icon: Badge(
              label: Text(
                _selectedRadiusKm == null
                    ? 'Все'
                    : '${_selectedRadiusKm!.toInt()}км',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showRadiusFilterDialog,
            tooltip: 'Фильтр радиуса',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _requestLocationPermission,
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialLocation,
              zoom: _defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: _onCameraMove,
          ),

          // Category filter chips
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CategoryChipSelector(
                selectedCategories: _selectedCategories,
                onCategoryToggled: _onCategoryToggled,
                showAllOption: true,
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Error message with action button
          if (_errorMessage != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.error,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                      // Show button to open settings if permission denied forever
                      if (_errorMessage!.contains('Измените настройки'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Открыть настройки'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateEventPressed,
        icon: const Icon(Icons.add),
        label: const Text('Создать событие'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
