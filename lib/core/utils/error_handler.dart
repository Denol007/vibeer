import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/events/services/events_service.dart';
import '../../features/events/services/join_requests_service.dart';
import '../../features/chat/services/chat_service.dart';
import '../../features/safety/services/safety_service.dart';
import 'app_logger.dart';
import '../theme/colors.dart';

/// Centralized error handling utility for Vibe app
///
/// Provides consistent error messages in Russian and standard error display patterns.
class ErrorHandler {
  ErrorHandler._();

  /// Convert exception to user-friendly Russian error message
  static String getMessage(dynamic error) {
    if (error == null) return 'Произошла неизвестная ошибка';

    // Auth exceptions
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }

    // Profile exceptions
    if (error is ProfileException) {
      return _getProfileErrorMessage(error);
    }

    // Events exceptions
    if (error is EventException) {
      return _getEventsErrorMessage(error);
    }

    // Join requests exceptions
    if (error is JoinRequestException) {
      return _getJoinRequestsErrorMessage(error);
    }

    // Chat exceptions
    if (error is ChatException) {
      return _getChatErrorMessage(error);
    }

    // Safety exceptions
    if (error is SafetyException) {
      return _getSafetyErrorMessage(error);
    }

    // Firebase Auth exceptions
    if (error is firebase_auth.FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    }

    // Firestore exceptions
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    }

    // Storage exceptions
    if (error is FirebaseException) {
      return _getFirebaseStorageErrorMessage(error);
    }

    // Generic error
    if (error is Exception) {
      final message = error.toString();
      // Remove "Exception: " prefix if present
      return message.replaceFirst('Exception: ', '');
    }

    return error.toString();
  }

  /// Get auth-specific error message
  static String _getAuthErrorMessage(AuthException error) {
    if (error is AuthCancelledException) {
      return 'Вход отменён';
    }
    return error.message;
  }

  /// Get profile-specific error message
  static String _getProfileErrorMessage(ProfileException error) {
    if (error is ProfileNotFoundException) {
      return 'Профиль не найден';
    }
    if (error is ProfileValidationException) {
      return error.message;
    }
    if (error is ProfileUploadException) {
      return 'Ошибка загрузки фото. Попробуйте ещё раз';
    }
    return error.message;
  }

  /// Get events-specific error message
  static String _getEventsErrorMessage(EventException error) {
    if (error is EventNotFoundException) {
      return 'Событие не найдено';
    }
    if (error is EventValidationException) {
      return error.message;
    }
    if (error is EventPermissionException) {
      return 'Нет прав для выполнения действия';
    }
    if (error is EventFullException) {
      return 'Событие заполнено';
    }
    return error.message;
  }

  /// Get join requests-specific error message
  static String _getJoinRequestsErrorMessage(JoinRequestException error) {
    if (error is RequestNotFoundException) {
      return 'Запрос не найден';
    }
    if (error is DuplicateRequestException) {
      return 'Вы уже отправили запрос на это событие';
    }
    if (error is SelfJoinException) {
      return 'Вы не можете отправить запрос на своё событие';
    }
    if (error is RequestPermissionException) {
      return 'Нет прав для выполнения действия';
    }
    return error.message;
  }

  /// Get chat-specific error message
  static String _getChatErrorMessage(ChatException error) {
    if (error is ChatNotFoundException) {
      return 'Чат не найден';
    }
    if (error is ChatPermissionException) {
      return 'Нет доступа к чату';
    }
    if (error is MessageTooLongException) {
      return 'Сообщение слишком длинное (макс. 1000 символов)';
    }
    return error.message;
  }

  /// Get safety-specific error message
  static String _getSafetyErrorMessage(SafetyException error) {
    return error.message;
  }

  /// Get Firebase Auth error message
  static String _getFirebaseAuthErrorMessage(
    firebase_auth.FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'weak-password':
        return 'Слишком простой пароль';
      case 'network-request-failed':
        return 'Проблема с подключением к интернету';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'account-exists-with-different-credential':
        return 'Аккаунт с таким email уже существует';
      case 'invalid-credential':
        return 'Неверные учётные данные';
      default:
        return 'Ошибка авторизации: ${error.message ?? error.code}';
    }
  }

  /// Get Firebase error message
  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Нет доступа к данным';
      case 'unavailable':
        return 'Сервис временно недоступен';
      case 'not-found':
        return 'Данные не найдены';
      case 'already-exists':
        return 'Данные уже существуют';
      case 'deadline-exceeded':
        return 'Превышено время ожидания';
      case 'resource-exhausted':
        return 'Превышен лимит запросов';
      case 'cancelled':
        return 'Операция отменена';
      case 'data-loss':
        return 'Потеря данных';
      case 'unauthenticated':
        return 'Требуется авторизация';
      case 'invalid-argument':
        return 'Неверные данные';
      case 'aborted':
        return 'Операция прервана';
      default:
        return 'Ошибка сервера: ${error.message ?? error.code}';
    }
  }

  /// Get Firebase Storage error message
  static String _getFirebaseStorageErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'object-not-found':
        return 'Файл не найден';
      case 'unauthorized':
        return 'Нет доступа к файлу';
      case 'canceled':
        return 'Загрузка отменена';
      case 'unknown':
        return 'Неизвестная ошибка загрузки';
      case 'retry-limit-exceeded':
        return 'Превышен лимит попыток';
      default:
        return 'Ошибка загрузки: ${error.message ?? error.code}';
    }
  }

  /// Log error for debugging
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('Error occurred', error, stackTrace);
  }

  /// Show error in snackbar
  static void showErrorSnackbar(BuildContext context, dynamic error) {
    final message = getMessage(error);
    logError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ОК',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error in dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final message = getMessage(error);
    logError(error);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Ошибка'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Повторить'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      return error.code == 'network-request-failed';
    }
    if (error is FirebaseException) {
      return error.code == 'unavailable' || error.code == 'deadline-exceeded';
    }
    return false;
  }

  /// Check if error is permission-related
  static bool isPermissionError(dynamic error) {
    if (error is EventPermissionException) return true;
    if (error is ChatPermissionException) return true;
    if (error is RequestPermissionException) return true;
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'unauthenticated';
    }
    return false;
  }

  /// Check if error is validation-related
  static bool isValidationError(dynamic error) {
    return error is ProfileValidationException ||
        error is EventValidationException ||
        error is MessageTooLongException;
  }
}
