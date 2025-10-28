import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vibe_app/core/utils/error_handler.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/services/profile_service.dart';
import 'package:vibe_app/features/events/services/events_service.dart';
import 'package:vibe_app/features/events/services/join_requests_service.dart';
import 'package:vibe_app/features/chat/services/chat_service.dart';
import 'package:vibe_app/features/safety/services/safety_service.dart';

void main() {
  group('ErrorHandler.getMessage - Auth Exceptions', () {
    test('returns Russian message for AuthCancelledException', () {
      final error = AuthCancelledException('OAuth cancelled');
      expect(ErrorHandler.getMessage(error), 'Вход отменён');
    });

    test('returns message from generic AuthException', () {
      final error = AuthException('Test auth error');
      expect(ErrorHandler.getMessage(error), 'Test auth error');
    });
  });

  group('ErrorHandler.getMessage - Profile Exceptions', () {
    test('returns Russian message for ProfileNotFoundException', () {
      final error = ProfileNotFoundException('user123');
      expect(ErrorHandler.getMessage(error), 'Профиль не найден');
    });

    test('returns message from ProfileValidationException', () {
      final error = ProfileValidationException('Validation failed');
      expect(ErrorHandler.getMessage(error), 'Validation failed');
    });

    test('returns Russian message for ProfileUploadException', () {
      final error = ProfileUploadException('Upload failed');
      expect(
        ErrorHandler.getMessage(error),
        'Ошибка загрузки фото. Попробуйте ещё раз',
      );
    });

    test('returns message from generic ProfileException', () {
      final error = ProfileException('Generic profile error');
      expect(ErrorHandler.getMessage(error), 'Generic profile error');
    });
  });

  group('ErrorHandler.getMessage - Event Exceptions', () {
    test('returns Russian message for EventNotFoundException', () {
      final error = EventNotFoundException('event123');
      expect(ErrorHandler.getMessage(error), 'Событие не найдено');
    });

    test('returns message from EventValidationException', () {
      final error = EventValidationException('Invalid event data');
      expect(ErrorHandler.getMessage(error), 'Invalid event data');
    });

    test('returns Russian message for EventPermissionException', () {
      final error = EventPermissionException('No permission');
      expect(
        ErrorHandler.getMessage(error),
        'Нет прав для выполнения действия',
      );
    });

    test('returns Russian message for EventFullException', () {
      final error = EventFullException('event123');
      expect(ErrorHandler.getMessage(error), 'Событие заполнено');
    });

    test('returns message from generic EventException', () {
      final error = EventException('Generic event error');
      expect(ErrorHandler.getMessage(error), 'Generic event error');
    });
  });

  group('ErrorHandler.getMessage - Join Request Exceptions', () {
    test('returns Russian message for RequestNotFoundException', () {
      final error = RequestNotFoundException('request123');
      expect(ErrorHandler.getMessage(error), 'Запрос не найден');
    });

    test('returns Russian message for DuplicateRequestException', () {
      final error = DuplicateRequestException('Duplicate request');
      expect(
        ErrorHandler.getMessage(error),
        'Вы уже отправили запрос на это событие',
      );
    });

    test('returns Russian message for SelfJoinException', () {
      final error = SelfJoinException('event123');
      expect(
        ErrorHandler.getMessage(error),
        'Вы не можете отправить запрос на своё событие',
      );
    });

    test('returns Russian message for RequestPermissionException', () {
      final error = RequestPermissionException('No permission');
      expect(
        ErrorHandler.getMessage(error),
        'Нет прав для выполнения действия',
      );
    });

    test('returns message from generic JoinRequestException', () {
      final error = JoinRequestException('Generic request error');
      expect(ErrorHandler.getMessage(error), 'Generic request error');
    });
  });

  group('ErrorHandler.getMessage - Chat Exceptions', () {
    test('returns Russian message for ChatNotFoundException', () {
      final error = ChatNotFoundException('chat123');
      expect(ErrorHandler.getMessage(error), 'Чат не найден');
    });

    test('returns Russian message for ChatPermissionException', () {
      final error = ChatPermissionException('No access');
      expect(ErrorHandler.getMessage(error), 'Нет доступа к чату');
    });

    test('returns Russian message for MessageTooLongException', () {
      final error = MessageTooLongException('Message is 1500 characters');
      expect(
        ErrorHandler.getMessage(error),
        'Сообщение слишком длинное (макс. 1000 символов)',
      );
    });

    test('returns message from generic ChatException', () {
      final error = ChatException('Generic chat error');
      expect(ErrorHandler.getMessage(error), 'Generic chat error');
    });
  });

  group('ErrorHandler.getMessage - Safety Exceptions', () {
    test('returns message from SafetyException', () {
      final error = SafetyException('Safety issue detected');
      expect(ErrorHandler.getMessage(error), 'Safety issue detected');
    });
  });

  group('ErrorHandler.getMessage - Firebase Auth Exceptions', () {
    test('returns Russian message for user-not-found', () {
      final error = firebase_auth.FirebaseAuthException(code: 'user-not-found');
      expect(ErrorHandler.getMessage(error), 'Пользователь не найден');
    });

    test('returns Russian message for wrong-password', () {
      final error = firebase_auth.FirebaseAuthException(code: 'wrong-password');
      expect(ErrorHandler.getMessage(error), 'Неверный пароль');
    });

    test('returns Russian message for invalid-email', () {
      final error = firebase_auth.FirebaseAuthException(code: 'invalid-email');
      expect(ErrorHandler.getMessage(error), 'Неверный формат email');
    });

    test('returns Russian message for user-disabled', () {
      final error = firebase_auth.FirebaseAuthException(code: 'user-disabled');
      expect(ErrorHandler.getMessage(error), 'Аккаунт заблокирован');
    });

    test('returns Russian message for email-already-in-use', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'email-already-in-use',
      );
      expect(ErrorHandler.getMessage(error), 'Email уже используется');
    });

    test('returns Russian message for operation-not-allowed', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'operation-not-allowed',
      );
      expect(ErrorHandler.getMessage(error), 'Операция не разрешена');
    });

    test('returns Russian message for weak-password', () {
      final error = firebase_auth.FirebaseAuthException(code: 'weak-password');
      expect(ErrorHandler.getMessage(error), 'Слишком простой пароль');
    });

    test('returns Russian message for network-request-failed', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'network-request-failed',
      );
      expect(
        ErrorHandler.getMessage(error),
        'Проблема с подключением к интернету',
      );
    });

    test('returns Russian message for too-many-requests', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'too-many-requests',
      );
      expect(
        ErrorHandler.getMessage(error),
        'Слишком много попыток. Попробуйте позже',
      );
    });

    test(
      'returns Russian message for account-exists-with-different-credential',
      () {
        final error = firebase_auth.FirebaseAuthException(
          code: 'account-exists-with-different-credential',
        );
        expect(
          ErrorHandler.getMessage(error),
          'Аккаунт с таким email уже существует',
        );
      },
    );

    test('returns Russian message for invalid-credential', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'invalid-credential',
      );
      expect(ErrorHandler.getMessage(error), 'Неверные учётные данные');
    });

    test('returns formatted message for unknown Firebase Auth error', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Something went wrong',
      );
      expect(
        ErrorHandler.getMessage(error),
        'Ошибка авторизации: Something went wrong',
      );
    });

    test(
      'returns formatted message for unknown Firebase Auth error with no message',
      () {
        final error = firebase_auth.FirebaseAuthException(
          code: 'unknown-error',
        );
        expect(
          ErrorHandler.getMessage(error),
          'Ошибка авторизации: unknown-error',
        );
      },
    );
  });

  group('ErrorHandler.getMessage - Firebase Exceptions', () {
    test('returns Russian message for permission-denied', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
      );
      expect(ErrorHandler.getMessage(error), 'Нет доступа к данным');
    });

    test('returns Russian message for unavailable', () {
      final error = FirebaseException(plugin: 'firestore', code: 'unavailable');
      expect(ErrorHandler.getMessage(error), 'Сервис временно недоступен');
    });

    test('returns Russian message for not-found', () {
      final error = FirebaseException(plugin: 'firestore', code: 'not-found');
      expect(ErrorHandler.getMessage(error), 'Данные не найдены');
    });

    test('returns Russian message for already-exists', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'already-exists',
      );
      expect(ErrorHandler.getMessage(error), 'Данные уже существуют');
    });

    test('returns Russian message for deadline-exceeded', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'deadline-exceeded',
      );
      expect(ErrorHandler.getMessage(error), 'Превышено время ожидания');
    });

    test('returns Russian message for resource-exhausted', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'resource-exhausted',
      );
      expect(ErrorHandler.getMessage(error), 'Превышен лимит запросов');
    });

    test('returns Russian message for cancelled', () {
      final error = FirebaseException(plugin: 'firestore', code: 'cancelled');
      expect(ErrorHandler.getMessage(error), 'Операция отменена');
    });

    test('returns Russian message for data-loss', () {
      final error = FirebaseException(plugin: 'firestore', code: 'data-loss');
      expect(ErrorHandler.getMessage(error), 'Потеря данных');
    });

    test('returns Russian message for unauthenticated', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
      );
      expect(ErrorHandler.getMessage(error), 'Требуется авторизация');
    });

    test('returns Russian message for invalid-argument', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'invalid-argument',
      );
      expect(ErrorHandler.getMessage(error), 'Неверные данные');
    });

    test('returns Russian message for aborted', () {
      final error = FirebaseException(plugin: 'firestore', code: 'aborted');
      expect(ErrorHandler.getMessage(error), 'Операция прервана');
    });

    test('returns formatted message for unknown Firebase error', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'unknown-error',
        message: 'Something went wrong',
      );
      expect(
        ErrorHandler.getMessage(error),
        'Ошибка сервера: Something went wrong',
      );
    });
  });

  group('ErrorHandler.getMessage - Firebase Storage Exceptions', () {
    test('returns Russian message for object-not-found', () {
      final error = FirebaseException(
        plugin: 'storage',
        code: 'object-not-found',
      );
      expect(ErrorHandler.getMessage(error), 'Файл не найден');
    });

    test('returns Russian message for unauthorized', () {
      final error = FirebaseException(plugin: 'storage', code: 'unauthorized');
      expect(ErrorHandler.getMessage(error), 'Нет доступа к файлу');
    });

    test('returns Russian message for canceled', () {
      final error = FirebaseException(plugin: 'storage', code: 'canceled');
      expect(ErrorHandler.getMessage(error), 'Загрузка отменена');
    });

    test('returns Russian message for unknown', () {
      final error = FirebaseException(plugin: 'storage', code: 'unknown');
      expect(ErrorHandler.getMessage(error), 'Неизвестная ошибка загрузки');
    });

    test('returns Russian message for retry-limit-exceeded', () {
      final error = FirebaseException(
        plugin: 'storage',
        code: 'retry-limit-exceeded',
      );
      expect(ErrorHandler.getMessage(error), 'Превышен лимит попыток');
    });

    test('returns formatted message for unknown storage error', () {
      final error = FirebaseException(
        plugin: 'storage',
        code: 'unknown-error',
        message: 'Upload failed',
      );
      expect(ErrorHandler.getMessage(error), 'Ошибка загрузки: Upload failed');
    });
  });

  group('ErrorHandler.getMessage - Generic Exceptions', () {
    test('returns null message as unknown error', () {
      expect(ErrorHandler.getMessage(null), 'Произошла неизвестная ошибка');
    });

    test('returns Exception message without "Exception:" prefix', () {
      final error = Exception('Something went wrong');
      expect(ErrorHandler.getMessage(error), 'Something went wrong');
    });

    test('returns plain string error as-is', () {
      final error = 'Plain error string';
      expect(ErrorHandler.getMessage(error), 'Plain error string');
    });

    test('handles unknown object types', () {
      final error = {'error': 'map error'};
      final result = ErrorHandler.getMessage(error);
      expect(result, isNotEmpty);
    });
  });

  group('ErrorHandler.isNetworkError', () {
    test('returns true for FirebaseAuthException network-request-failed', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'network-request-failed',
      );
      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('returns true for FirebaseException unavailable', () {
      final error = FirebaseException(plugin: 'firestore', code: 'unavailable');
      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('returns true for FirebaseException deadline-exceeded', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'deadline-exceeded',
      );
      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('returns false for non-network errors', () {
      final error1 = firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
      );
      expect(ErrorHandler.isNetworkError(error1), false);

      final error2 = FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
      );
      expect(ErrorHandler.isNetworkError(error2), false);

      final error3 = Exception('Generic error');
      expect(ErrorHandler.isNetworkError(error3), false);
    });
  });

  group('ErrorHandler.isPermissionError', () {
    test('returns true for EventPermissionException', () {
      final error = EventPermissionException('No permission');
      expect(ErrorHandler.isPermissionError(error), true);
    });

    test('returns true for ChatPermissionException', () {
      final error = ChatPermissionException('No access');
      expect(ErrorHandler.isPermissionError(error), true);
    });

    test('returns true for RequestPermissionException', () {
      final error = RequestPermissionException('No permission');
      expect(ErrorHandler.isPermissionError(error), true);
    });

    test('returns true for FirebaseException permission-denied', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
      );
      expect(ErrorHandler.isPermissionError(error), true);
    });

    test('returns true for FirebaseException unauthenticated', () {
      final error = FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
      );
      expect(ErrorHandler.isPermissionError(error), true);
    });

    test('returns false for non-permission errors', () {
      final error1 = EventNotFoundException('event123');
      expect(ErrorHandler.isPermissionError(error1), false);

      final error2 = ProfileValidationException('Invalid data');
      expect(ErrorHandler.isPermissionError(error2), false);

      final error3 = Exception('Generic error');
      expect(ErrorHandler.isPermissionError(error3), false);
    });
  });

  group('ErrorHandler.isValidationError', () {
    test('returns true for ProfileValidationException', () {
      final error = ProfileValidationException('Invalid profile');
      expect(ErrorHandler.isValidationError(error), true);
    });

    test('returns true for EventValidationException', () {
      final error = EventValidationException('Invalid event');
      expect(ErrorHandler.isValidationError(error), true);
    });

    test('returns true for MessageTooLongException', () {
      final error = MessageTooLongException('Message too long');
      expect(ErrorHandler.isValidationError(error), true);
    });

    test('returns false for non-validation errors', () {
      final error1 = EventNotFoundException('event123');
      expect(ErrorHandler.isValidationError(error1), false);

      final error2 = ChatPermissionException('No access');
      expect(ErrorHandler.isValidationError(error2), false);

      final error3 = Exception('Generic error');
      expect(ErrorHandler.isValidationError(error3), false);
    });
  });

  group('ErrorHandler.logError', () {
    test('logs error to console without throwing', () {
      // This test verifies that logError doesn't throw exceptions
      // In a real app with proper logging, you'd mock the logger
      expect(() => ErrorHandler.logError('Test error'), returnsNormally);
      expect(
        () => ErrorHandler.logError(Exception('Test exception')),
        returnsNormally,
      );
    });

    test('logs error with stack trace without throwing', () {
      final stackTrace = StackTrace.current;
      expect(
        () => ErrorHandler.logError('Test error', stackTrace),
        returnsNormally,
      );
    });
  });
}
