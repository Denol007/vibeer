/// Form Validation Utilities - T062
///
/// Collection of validation functions for form inputs.
/// Returns error message string if invalid, null if valid.
library;

/// Validate age is at least 18 and at most 25
String? validateAge(int? age) {
  if (age == null) {
    return 'Укажите возраст';
  }
  if (age < 18) {
    return 'Вам должно быть не менее 18 лет';
  }
  if (age > 25) {
    return 'Вам должно быть не более 25 лет';
  }
  return null;
}

/// Validate event start time is within next 24 hours
String? validateEventTime(DateTime? time) {
  if (time == null) {
    return 'Укажите время начала';
  }

  final now = DateTime.now();
  final diff = time.difference(now);

  if (diff.isNegative) {
    return 'Время начала не может быть в прошлом';
  }

  if (diff.inHours > 24) {
    return 'Событие должно начаться в течение 24 часов';
  }

  if (diff.inMinutes < 5) {
    return 'Минимум 5 минут до начала';
  }

  return null;
}

/// Validate number of participants is between 1 and 5
String? validateParticipants(int? count) {
  if (count == null) {
    return 'Укажите количество участников';
  }
  if (count < 1) {
    return 'Минимум 1 участник';
  }
  if (count > 5) {
    return 'Максимум 5 участников';
  }
  return null;
}

/// Validate text length
String? validateTextLength(
  String? text,
  int maxLength, {
  int minLength = 0,
  String? fieldName,
}) {
  final name = fieldName ?? 'Поле';

  if (text == null || text.trim().isEmpty) {
    if (minLength > 0) {
      return '$name обязательно';
    }
    return null;
  }

  final trimmed = text.trim();

  if (trimmed.length < minLength) {
    return '$name должно содержать не менее $minLength символов';
  }

  if (trimmed.length > maxLength) {
    return '$name должно содержать не более $maxLength символов';
  }

  return null;
}

/// Validate email format
String? validateEmail(String? email) {
  if (email == null || email.trim().isEmpty) {
    return 'Укажите email';
  }

  // Basic email regex pattern
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(email.trim())) {
    return 'Неверный формат email';
  }

  return null;
}

/// Validate required field (not empty)
String? validateRequired(String? value, {String? fieldName}) {
  final name = fieldName ?? 'Поле';

  if (value == null || value.trim().isEmpty) {
    return '$name обязательно';
  }

  return null;
}

/// Validate name (letters, spaces, hyphens only, 1-50 chars)
String? validateName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return 'Укажите имя';
  }

  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return 'Имя обязательно';
  }

  if (trimmed.length > 50) {
    return 'Имя должно содержать не более 50 символов';
  }

  // Allow letters, spaces, hyphens, apostrophes
  final nameRegex = RegExp(r"^[a-zA-Zа-яА-ЯёЁ\s'-]+$");

  if (!nameRegex.hasMatch(trimmed)) {
    return 'Имя может содержать только буквы, пробелы и дефисы';
  }

  return null;
}
