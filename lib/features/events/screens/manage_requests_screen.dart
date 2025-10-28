import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/join_request_model.dart';
import '../providers/join_requests_provider.dart';
import '../widgets/join_request_card.dart';

/// Manage Requests Screen - T052
///
/// Allows event organizers to review and approve/decline join requests.
/// Displays pending requests in real-time with approve/decline actions.
class ManageRequestsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ManageRequestsScreen({super.key, required this.eventId});

  @override
  ConsumerState<ManageRequestsScreen> createState() =>
      _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends ConsumerState<ManageRequestsScreen> {
  final Map<String, bool> _loadingRequests = {};

  /// Handle approve request
  Future<void> _handleApprove(String requestId) async {
    setState(() {
      _loadingRequests[requestId] = true;
    });

    try {
      final joinRequestsService = ref.read(joinRequestsServiceProvider);
      await joinRequestsService.approveRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запрос одобрен!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRequests[requestId] = false;
        });
      }
    }
  }

  /// Handle decline request
  Future<void> _handleDecline(String requestId) async {
    setState(() {
      _loadingRequests[requestId] = true;
    });

    try {
      final joinRequestsService = ref.read(joinRequestsServiceProvider);
      await joinRequestsService.declineRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запрос отклонён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRequests[requestId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinRequestsService = ref.watch(joinRequestsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Запросы на участие')),
      body: StreamBuilder<List<JoinRequestModel>>(
        stream: joinRequestsService.getEventRequests(widget.eventId),
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
                    'Ошибка загрузки запросов',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];
          final pendingRequests = requests
              .where((request) => request.status == 'pending')
              .toList();

          if (pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет запросов',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Запросы на участие появятся здесь',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingRequests.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              final isLoading = _loadingRequests[request.id] ?? false;

              return JoinRequestCard(
                request: request,
                onApprove: () => _handleApprove(request.id),
                onDecline: () => _handleDecline(request.id),
                isLoading: isLoading,
              );
            },
          );
        },
      ),
    );
  }
}
