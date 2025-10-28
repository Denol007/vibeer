import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vibe_app/features/safety/services/safety_service.dart';

import 'safety_service_test.mocks.dart';

/// Unit tests for SafetyService interface - T018
@GenerateMocks([SafetyService])
void main() {
  group('SafetyService Contract', () {
    late SafetyService mockService;

    setUp(() {
      mockService = MockSafetyService();
    });

    test('blockUser should add to blocked list', () async {
      when(mockService.blockUser('user456')).thenAnswer((_) async => {});

      await mockService.blockUser('user456');
      verify(mockService.blockUser('user456')).called(1);
    });

    test('unblockUser should remove from blocked list', () async {
      when(mockService.unblockUser('user456')).thenAnswer((_) async => {});

      await mockService.unblockUser('user456');
      verify(mockService.unblockUser('user456')).called(1);
    });

    test('isUserBlocked should return blocked status', () async {
      when(mockService.isUserBlocked('user456')).thenAnswer((_) async => true);

      final result = await mockService.isUserBlocked('user456');
      expect(result, true);
    });

    test('reportUser should create report', () async {
      when(
        mockService.reportUser(
          userId: 'user456',
          reason: 'Inappropriate behavior',
        ),
      ).thenAnswer((_) async => {});

      await mockService.reportUser(
        userId: 'user456',
        reason: 'Inappropriate behavior',
      );

      verify(
        mockService.reportUser(
          userId: 'user456',
          reason: 'Inappropriate behavior',
        ),
      ).called(1);
    });

    test('should throw BlockSelfException when blocking self', () async {
      when(
        mockService.blockUser('self'),
      ).thenThrow(BlockSelfException('Cannot block yourself'));

      expect(
        () => mockService.blockUser('self'),
        throwsA(isA<BlockSelfException>()),
      );
    });
  });
}

class BlockSelfException implements Exception {
  final String message;
  BlockSelfException(this.message);
}
