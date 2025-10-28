/// Abstract interface for safety service
abstract class SafetyService {
  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUsers();

  /// Block a user
  Future<void> blockUser(String userId);

  /// Unblock a user
  Future<void> unblockUser(String userId);

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId);

  /// Report a user
  Future<void> reportUser({required String userId, required String reason});

  /// Report an event
  Future<void> reportEvent({required String eventId, required String reason});
}

class SafetyException implements Exception {
  final String message;
  const SafetyException(this.message);
  @override
  String toString() => 'SafetyException: $message';
}

class BlockSelfException extends SafetyException {
  const BlockSelfException(super.message);
}

class ReportValidationException extends SafetyException {
  const ReportValidationException(super.message);
}
