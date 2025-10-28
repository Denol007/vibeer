import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/event_model.dart';
import '../models/join_request_model.dart';
import '../providers/events_provider.dart';
import '../providers/join_requests_provider.dart';
import '../services/events_service.dart';
import '../services/join_requests_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Event detail screen - T051
///
/// Displays full event information with actions:
/// - Join button for non-participants
/// - Manage Requests button for organizer
/// - Open Chat button for participants
/// - Cancel Event button for organizer
class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isJoining = false;
  bool _isDeleting = false;
  String? _errorMessage;

  /// Format date time for Russian display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) {
      return 'Сегодня в ${DateFormat('HH:mm').format(dateTime)}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Завтра в ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('d MMMM в HH:mm', 'ru').format(dateTime);
    }
  }

  /// Handle join button tap
  Future<void> _handleJoin(
    JoinRequestsService joinRequestsService,
    String eventId,
  ) async {
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await joinRequestsService.sendJoinRequest(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос на участие отправлен!')),
        );
      }
    } on JoinRequestException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  /// Handle delete event button tap
  Future<void> _handleDelete(
    EventsService eventsService,
    String eventId,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие?'),
        content: const Text(
          'Событие будет удалено полностью и навсегда. '
          'Это действие невозможно отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await eventsService.deleteEvent(eventId);
      if (mounted) {
        context.go('/home'); // Go to home after deletion
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Событие удалено')));
      }
    } on EventException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  /// Handle share event button
  Future<void> _handleShare(BuildContext context) async {
    final eventId = widget.eventId;
    
    // Copy event ID to clipboard
    await Clipboard.setData(ClipboardData(text: eventId));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID события скопирован: $eventId'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsService = ref.watch(eventsServiceProvider);
    final joinRequestsService = ref.watch(joinRequestsServiceProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUserId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали события'),
        actions: [
          // Copy event ID button
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _handleShare(context),
            tooltip: 'Скопировать ID события',
          ),
        ],
      ),
      body: FutureBuilder<EventModel?>(
        future: eventsService.getEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки события',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Попробовать снова',
                    onPressed: () => setState(() {}),
                  ),
                ],
              ),
            );
          }

          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('Событие не найдено'));
          }

          final isOrganizer = event.organizerId == currentUserId;
          final isParticipant = event.participantIds.contains(currentUserId);
          final isFull =
              event.currentParticipants >= event.neededParticipants + 1;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Organizer info section
                GestureDetector(
                  onTap: () => context.push('/user/${event.organizerId}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: CachedNetworkImageProvider(
                            event.organizerPhotoUrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Organizer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.organizerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Event details section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(event.startTime),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.locationName ?? 'Местоположение на карте',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Participants
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${event.currentParticipants}/${event.neededParticipants + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFull ? 'участников (полный)' : 'участников',
                            style: TextStyle(
                              fontSize: 16,
                              color: isFull
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Описание',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 16),
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isOrganizer && !isParticipant)
                        CustomButton(
                          text: 'Want to join!',
                          onPressed: _isJoining || isFull
                              ? null
                              : () =>
                                    _handleJoin(joinRequestsService, event.id),
                          isLoading: _isJoining,
                        ),

                      if (isOrganizer) ...[
                        // Manage requests button with badge
                        StreamBuilder<List<JoinRequestModel>>(
                          stream: joinRequestsService.getEventRequests(event.id),
                          builder: (context, snapshot) {
                            final pendingCount = snapshot.data
                                    ?.where((req) => req.status == 'pending')
                                    .length ?? 0;
                            
                            return Stack(
                              children: [
                                CustomButton(
                                  text: 'Управление запросами',
                                  onPressed: () {
                                    context.push('/event/${event.id}/requests');
                                  },
                                ),
                                if (pendingCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$pendingCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (isParticipant)
                        CustomButton(
                          text: 'Открыть чат',
                          onPressed: () {
                            context.push('/chat/${event.id}');
                          },
                        ),

                      // View participants button (for organizer or participants)
                      if (isOrganizer || isParticipant) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.people_outline),
                          label: Text(
                            'Смотреть участников (${event.currentParticipants})',
                          ),
                          onPressed: () {
                            final participantIds = event.participantIds.join(',');
                            context.push(
                              '/event/${event.id}/participants?organizerId=${event.organizerId}&participantIds=$participantIds',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],

                      if (isOrganizer) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isDeleting
                              ? null
                              : () => _handleDelete(eventsService, event.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isDeleting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Удалить событие'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
