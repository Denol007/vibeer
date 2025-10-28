import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/colors.dart';
import '../models/event_model.dart';

/// Event card widget for displaying event in list view
///
/// Shows event title, organizer info, time, location, participant count, and distance.
/// Tappable to open event details.
class EventCard extends StatelessWidget {
  final EventModel event;
  final Position? userPosition;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    this.userPosition,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inMinutes.abs() <= 15) {
      return 'Сейчас';
    } else if (difference.inMinutes > 0 && difference.inHours < 1) {
      return 'Через ${difference.inMinutes} мин';
    } else if (difference.inHours > 0 && difference.inHours < 24) {
      return 'Через ${difference.inHours} ч';
    } else if (now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return 'Сегодня в ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.day + 1 == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return 'Завтра в ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month} в ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String? _formatDistance() {
    if (userPosition == null) return null;

    final distanceInMeters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      event.location.latitude,
      event.location.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} км';
    }
  }

  Color _getStatusColor() {
    final now = DateTime.now();
    final minutesUntilStart = event.startTime.difference(now).inMinutes;
    final isFull = event.currentParticipants >= event.neededParticipants + 1;

    if (minutesUntilStart.abs() <= 15) {
      return Colors.purple; // Happening now
    } else if (isFull) {
      return Colors.red; // Full
    } else if (minutesUntilStart > 0 && minutesUntilStart <= 60) {
      return Colors.orange; // Starting soon
    } else {
      return Colors.green; // Regular
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = _formatDistance();
    final statusColor = _getStatusColor();
    final isFull = event.currentParticipants >= event.neededParticipants + 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title, status indicator, and category badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.category.lightColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: event.category.color,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.category.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.category.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: event.category.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Organizer info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(
                      event.organizerPhotoUrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.organizerName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time and location
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(event.startTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.locationName ?? 'Неизвестно',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Participants count and distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isFull ? Colors.red : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentParticipants}/${event.neededParticipants + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isFull ? Colors.red : AppColors.primary,
                        ),
                      ),
                      if (isFull) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Набрано',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                  if (distance != null)
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
