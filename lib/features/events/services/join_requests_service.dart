import 'package:vibe_app/features/events/models/join_request_model.dart';

/// Abstract interface for join requests service
abstract class JoinRequestsService {
  /// Stream of join requests for events organized by current user
  Stream<List<JoinRequestModel>> getIncomingRequests();

  /// Stream of join requests sent by current user
  Stream<List<JoinRequestModel>> getMyRequests();

  /// Get join requests for specific event
  Stream<List<JoinRequestModel>> getEventRequests(String eventId);

  /// Send join request to event
  Future<JoinRequestModel> sendJoinRequest(String eventId);

  /// Approve join request (organizer only)
  Future<void> approveRequest(String requestId);

  /// Decline join request (organizer only)
  Future<void> declineRequest(String requestId);

  /// Auto-decline pending requests when event is full
  Future<void> autoDeclinePendingRequests(String eventId);
}

class JoinRequestException implements Exception {
  final String message;
  const JoinRequestException(this.message);
  @override
  String toString() => 'JoinRequestException: $message';
}

class DuplicateRequestException extends JoinRequestException {
  const DuplicateRequestException(super.message);
}

class SelfJoinException extends JoinRequestException {
  const SelfJoinException(super.message);
}

class RequestNotFoundException extends JoinRequestException {
  const RequestNotFoundException(super.message);
}

class RequestPermissionException extends JoinRequestException {
  const RequestPermissionException(super.message);
}
