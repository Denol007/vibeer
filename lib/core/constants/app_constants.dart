/// Application-wide constants derived from functional requirements
class AppConstants {
  // Age restrictions (FR-001)
  static const int minAge = 18;
  static const int maxAge = 25;

  // Event participant limits (FR-007, FR-008)
  static const int minNeededParticipants = 1;
  static const int maxNeededParticipants = 5;

  // Event timing constraints (FR-006, FR-022)
  static const int eventMaxDurationHours = 24;
  static const int eventArchiveAfterHours = 1;

  // Text length limits (FR-009, FR-010, FR-034)
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxAboutMeLength = 500;
  static const int maxMessageLength = 1000;

  // Map and location settings (FR-015, FR-016)
  static const double initialZoomLevel = 14.0;
  static const double maxZoomLevel = 18.0;
  static const double minZoomLevel = 10.0;
  static const double eventRadiusMeters = 100.0; // Event location accuracy
  static const double mapSearchRadiusKm = 10.0; // Default search radius

  // Chat settings (FR-035, FR-037)
  static const int chatMessagesLimit = 50;
  static const int maxChatMembers = 6; // Creator + maxNeededParticipants

  // Join request timeout (FR-024)
  static const int joinRequestTimeoutMinutes = 10;

  // Pagination
  static const int defaultPageSize = 20;
  static const int eventsPerPage = 10;

  // Safety features (FR-045, FR-048)
  static const int minReportReasonLength = 10;
  static const int maxReportReasonLength = 500;

  // Image upload constraints (FR-003)
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // Session and cache
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration sessionTimeout = Duration(days: 30);

  // Network settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Validation error messages
  static const String errorMinAge = 'Вам должно быть от 18 до 25 лет';
  static const String errorInvalidEmail = 'Неверный формат email';
  static const String errorRequiredField = 'Обязательное поле';
  static const String errorTitleTooLong =
      'Название слишком длинное (макс. 100 символов)';
  static const String errorDescriptionTooLong =
      'Описание слишком длинное (макс. 500 символов)';
  static const String errorMessageTooLong =
      'Сообщение слишком длинное (макс. 1000 символов)';
  static const String errorInvalidParticipants =
      'Количество участников должно быть от 1 до 5';
  static const String errorEventTooLong =
      'Событие не может длиться больше 24 часов';

  // Feature flags (for gradual rollout)
  static const bool enablePushNotifications = true;
  static const bool enableLocationSharing = true;
  static const bool enableImageCompression = true;
  static const bool enableOfflineMode = false; // Future feature

  // API endpoints (to be configured with Firebase)
  static const String apiBaseUrl = ''; // Firebase auto-configured

  // Private constructor to prevent instantiation
  AppConstants._();
}
