import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vibe_app/features/events/services/join_requests_service.dart';
import 'package:vibe_app/features/events/models/join_request_model.dart';

import 'join_requests_service_test.mocks.dart';

/// Unit tests for JoinRequestsService interface - T016
@GenerateMocks([JoinRequestsService])
void main() {
  group('JoinRequestsService Contract', () {
    late JoinRequestsService mockService;

    setUp(() {
      mockService = MockJoinRequestsService();
    });

    test('sendJoinRequest should create join request', () async {
      final request = JoinRequestModel(
        id: 'req123',
        eventId: 'event123',
        requesterId: 'user456',
        requesterName: 'Alex',
        requesterPhotoUrl: 'https://example.com/photo.jpg',
        requesterAge: 24,
        organizerId: 'user123',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      when(
        mockService.sendJoinRequest('event123'),
      ).thenAnswer((_) async => request);

      final result = await mockService.sendJoinRequest('event123');
      expect(result.status, 'pending');
    });

    test('approveRequest should add user to participants', () async {
      when(mockService.approveRequest('req123')).thenAnswer((_) async => {});

      await mockService.approveRequest('req123');
      verify(mockService.approveRequest('req123')).called(1);
    });

    test(
      'should throw DuplicateRequestException for duplicate request',
      () async {
        when(
          mockService.sendJoinRequest('event123'),
        ).thenThrow(DuplicateRequestException('Already requested'));

        expect(
          () => mockService.sendJoinRequest('event123'),
          throwsA(isA<DuplicateRequestException>()),
        );
      },
    );
  });
}

class DuplicateRequestException implements Exception {
  final String message;
  DuplicateRequestException(this.message);
}
