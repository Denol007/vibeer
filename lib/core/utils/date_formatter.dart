import 'package:intl/intl.dart';

/// Date/Time Formatting Utilities - T063
///
/// Collection of date and time formatting functions for Russian locale.
/// Provides consistent date/time display across the app.

/// Format event start time for Russian locale
/// Examples: "Сейчас", "Через 5 минут", "Сегодня в 19:00", "Завтра в 14:30"
String formatEventTime(DateTime eventTime) {
  final now = DateTime.now();
  final diff = eventTime.difference(now);

  // Happening now (within 15 minutes of start)
  if (diff.inMinutes.abs() <= 15 && diff.inMinutes >= 0) {
    return 'Сейчас';
  }

  // Starting soon (less than 1 hour)
  if (diff.inMinutes > 0 && diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    final minutesWord = _getRussianMinutesWord(minutes);
    return 'Через $minutes $minutesWord';
  }

  final today = DateTime(now.year, now.month, now.day);
  final eventDate = DateTime(eventTime.year, eventTime.month, eventTime.day);

  // Today
  if (eventDate == today) {
    return 'Сегодня в ${DateFormat('HH:mm').format(eventTime)}';
  }

  // Tomorrow
  if (eventDate == today.add(const Duration(days: 1))) {
    return 'Завтра в ${DateFormat('HH:mm').format(eventTime)}';
  }

  // Within this week
  if (diff.inDays < 7) {
    final weekday = _getRussianWeekday(eventTime.weekday);
    return '$weekday в ${DateFormat('HH:mm').format(eventTime)}';
  }

  // Future date
  return DateFormat('d MMMM в HH:mm', 'ru').format(eventTime);
}

/// Format timestamp for chat messages
/// Examples: "Только что", "5 минут назад", "Вчера в 14:30", "15 сентября"
String formatChatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  // Just now (less than 1 minute)
  if (diff.inMinutes < 1) {
    return 'Только что';
  }

  // Minutes ago (less than 1 hour)
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    final minutesWord = _getRussianMinutesWord(minutes);
    return '$minutes $minutesWord назад';
  }

  // Hours ago (less than 24 hours)
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    final hoursWord = _getRussianHoursWord(hours);
    return '$hours $hoursWord назад';
  }

  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  // Yesterday
  if (messageDate == today.subtract(const Duration(days: 1))) {
    return 'Вчера в ${DateFormat('HH:mm').format(timestamp)}';
  }

  // Within this week
  if (diff.inDays < 7) {
    final weekday = _getRussianWeekday(timestamp.weekday);
    return '$weekday в ${DateFormat('HH:mm').format(timestamp)}';
  }

  // Older (show date)
  return DateFormat('d MMMM', 'ru').format(timestamp);
}

/// Format relative time
/// Examples: "5 минут назад", "2 часа назад", "3 дня назад"
String formatRelativeTime(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  // Just now
  if (diff.inSeconds < 60) {
    return 'Только что';
  }

  // Minutes
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    final minutesWord = _getRussianMinutesWord(minutes);
    return '$minutes $minutesWord назад';
  }

  // Hours
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    final hoursWord = _getRussianHoursWord(hours);
    return '$hours $hoursWord назад';
  }

  // Days
  if (diff.inDays < 30) {
    final days = diff.inDays;
    final daysWord = _getRussianDaysWord(days);
    return '$days $daysWord назад';
  }

  // Months
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    final monthsWord = _getRussianMonthsWord(months);
    return '$months $monthsWord назад';
  }

  // Years
  final years = (diff.inDays / 365).floor();
  final yearsWord = _getRussianYearsWord(years);
  return '$years $yearsWord назад';
}

/// Format time only (HH:mm)
String formatTimeOnly(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

/// Format date only (d MMMM yyyy)
String formatDateOnly(DateTime date) {
  return DateFormat('d MMMM yyyy', 'ru').format(date);
}

/// Format date and time (d MMMM yyyy в HH:mm)
String formatDateTime(DateTime dateTime) {
  return DateFormat('d MMMM yyyy в HH:mm', 'ru').format(dateTime);
}

// Private helper functions

/// Get Russian weekday name
String _getRussianWeekday(int weekday) {
  const weekdays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  return weekdays[weekday - 1];
}

/// Get Russian word for minutes (with correct declension)
String _getRussianMinutesWord(int minutes) {
  if (minutes % 10 == 1 && minutes % 100 != 11) {
    return 'минуту';
  } else if ([2, 3, 4].contains(minutes % 10) &&
      ![12, 13, 14].contains(minutes % 100)) {
    return 'минуты';
  } else {
    return 'минут';
  }
}

/// Get Russian word for hours (with correct declension)
String _getRussianHoursWord(int hours) {
  if (hours % 10 == 1 && hours % 100 != 11) {
    return 'час';
  } else if ([2, 3, 4].contains(hours % 10) &&
      ![12, 13, 14].contains(hours % 100)) {
    return 'часа';
  } else {
    return 'часов';
  }
}

/// Get Russian word for days (with correct declension)
String _getRussianDaysWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) {
    return 'день';
  } else if ([2, 3, 4].contains(days % 10) &&
      ![12, 13, 14].contains(days % 100)) {
    return 'дня';
  } else {
    return 'дней';
  }
}

/// Get Russian word for months (with correct declension)
String _getRussianMonthsWord(int months) {
  if (months % 10 == 1 && months % 100 != 11) {
    return 'месяц';
  } else if ([2, 3, 4].contains(months % 10) &&
      ![12, 13, 14].contains(months % 100)) {
    return 'месяца';
  } else {
    return 'месяцев';
  }
}

/// Get Russian word for years (with correct declension)
String _getRussianYearsWord(int years) {
  if (years % 10 == 1 && years % 100 != 11) {
    return 'год';
  } else if ([2, 3, 4].contains(years % 10) &&
      ![12, 13, 14].contains(years % 100)) {
    return 'года';
  } else {
    return 'лет';
  }
}
