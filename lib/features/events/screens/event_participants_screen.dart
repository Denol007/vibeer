import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/user_model.dart';

/// Screen displaying list of event participants
///
/// Shows organizer and all participants with their profiles
class EventParticipantsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String organizerId;
  final List<String> participantIds;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.organizerId,
    required this.participantIds,
  });

  @override
  ConsumerState<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState
    extends ConsumerState<EventParticipantsScreen> {
  Map<String, UserModel> _participants = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final allUserIds = [widget.organizerId, ...widget.participantIds];
      final Map<String, UserModel> loadedProfiles = {};

      // Load all participant profiles
      for (final userId in allUserIds) {
        try {
          final profile = await profileService.getProfile(userId);
          if (profile != null) {
            loadedProfiles[userId] = profile;
          }
        } catch (e) {
          print('⚠️ Error loading profile for $userId: $e');
        }
      }

      setState(() {
        _participants = loadedProfiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки участников';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = 1 + widget.participantIds.length; // organizer + participants

    return Scaffold(
      appBar: AppBar(
        title: Text('Участники ($totalCount)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadParticipants,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _participants.isEmpty
                  ? const Center(
                      child: Text('Нет участников'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Organizer section
                        const Text(
                          'Организатор',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_participants.containsKey(widget.organizerId))
                          _buildParticipantCard(
                            _participants[widget.organizerId]!,
                            isOrganizer: true,
                          ),
                        const SizedBox(height: 24),

                        // Participants section
                        if (widget.participantIds.isNotEmpty) ...[
                          Text(
                            'Участники (${widget.participantIds.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.participantIds.map((participantId) {
                            if (_participants.containsKey(participantId)) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildParticipantCard(
                                  _participants[participantId]!,
                                  isOrganizer: false,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ],
                    ),
    );
  }

  Widget _buildParticipantCard(UserModel user, {required bool isOrganizer}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/user/${user.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile photo
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withAlpha(51),
                backgroundImage: user.profilePhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePhotoUrl)
                    : null,
                child: user.profilePhotoUrl.isEmpty
                    ? Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOrganizer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Организатор',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.age} лет',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (user.aboutMe != null && user.aboutMe!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.aboutMe!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
