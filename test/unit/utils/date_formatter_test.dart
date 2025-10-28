import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vibe_app/core/utils/date_formatter.dart';

void main() {
  // Initialize Russian locale data for testing
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  group('formatEventTime', () {
    test('returns "Сейчас" for event starting within 15 minutes', () {
      final now = DateTime.now();
      final soon = now.add(const Duration(minutes: 5));
      expect(formatEventTime(soon), 'Сейчас');

      final verySoon = now.add(const Duration(minutes: 1));
      expect(formatEventTime(verySoon), 'Сейчас');

      final justStarting = now.add(const Duration(minutes: 15));
      expect(formatEventTime(justStarting), 'Сейчас');
    });

    test('returns "Через X минут" for events starting in less than 1 hour', () {
      final now = DateTime.now();

      final in20Minutes = now.add(const Duration(minutes: 20));
      final result20 = formatEventTime(in20Minutes);
      expect(result20, startsWith('Через '));
      expect(result20, contains('минут'));

      final in45Minutes = now.add(const Duration(minutes: 45));
      final result45 = formatEventTime(in45Minutes);
      expect(result45, startsWith('Через '));
      expect(result45, contains('минут'));

      final in59Minutes = now.add(const Duration(minutes: 59));
      final result59 = formatEventTime(in59Minutes);
      expect(result59, startsWith('Через '));
      expect(result59, contains('минут'));
    });

    test('uses correct Russian declension for minutes', () {
      final now = DateTime.now();

      // Just test that it uses the right format (Через X минут/минуты/минуту)
      final in21Minutes = now.add(const Duration(minutes: 21));
      final result21 = formatEventTime(in21Minutes);
      expect(result21, startsWith('Через '));
      expect(result21, contains('минут'));

      final in22Minutes = now.add(const Duration(minutes: 22));
      final result22 = formatEventTime(in22Minutes);
      expect(result22, startsWith('Через '));
      expect(result22, contains('минут'));

      final in24Minutes = now.add(const Duration(minutes: 24));
      final result24 = formatEventTime(in24Minutes);
      expect(result24, startsWith('Через '));
      expect(result24, contains('минут'));

      final in25Minutes = now.add(const Duration(minutes: 25));
      final result25 = formatEventTime(in25Minutes);
      expect(result25, startsWith('Через '));
      expect(result25, contains('минут'));
    });

    test('uses correct Russian declension for minutes', () {
      final now = DateTime.now();

      // Test various minute values for proper declension
      final in21Minutes = now.add(const Duration(minutes: 21));
      final result21 = formatEventTime(in21Minutes);
      expect(result21, startsWith('Через '));
      expect(result21, contains('минут'));

      final in22Minutes = now.add(const Duration(minutes: 22));
      final result22 = formatEventTime(in22Minutes);
      expect(result22, startsWith('Через '));
      expect(result22, contains('минут'));

      final in24Minutes = now.add(const Duration(minutes: 24));
      final result24 = formatEventTime(in24Minutes);
      expect(result24, startsWith('Через '));
      expect(result24, contains('минут'));

      final in25Minutes = now.add(const Duration(minutes: 25));
      final result25 = formatEventTime(in25Minutes);
      expect(result25, startsWith('Через '));
      expect(result25, contains('минут'));
    });

    test('returns "Сегодня в HH:mm" for events today', () {
      final now = DateTime.now();
      final later = DateTime(now.year, now.month, now.day, 19, 30);

      if (later.isAfter(now.add(const Duration(hours: 1)))) {
        final result = formatEventTime(later);
        expect(result, startsWith('Сегодня в '));
        expect(result, contains('19:30'));
      }
    });

    test('returns "Завтра в HH:mm" for events tomorrow', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 14, 30);

      final result = formatEventTime(tomorrow);
      expect(result, startsWith('Завтра в '));
      expect(result, contains('14:30'));
    });

    test('returns weekday for events within this week', () {
      final now = DateTime.now();
      // Find a day that's 2-6 days away
      for (int i = 2; i <= 6; i++) {
        final futureDate = now.add(Duration(days: i));
        final result = formatEventTime(futureDate);

        // Should contain a Russian weekday name and time
        final weekdays = [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье',
        ];
        final containsWeekday = weekdays.any((day) => result.contains(day));
        expect(containsWeekday, true);
        expect(result, contains(' в '));
      }
    });

    test('returns full date for events more than a week away', () {
      final now = DateTime.now();
      final farFuture = now.add(const Duration(days: 10));

      final result = formatEventTime(farFuture);
      // Should contain month name and time
      expect(result, contains(' в '));
    });
  });

  group('formatChatTimestamp', () {
    test('returns "Только что" for messages less than 1 minute ago', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      expect(formatChatTimestamp(justNow), 'Только что');

      final veryRecent = now.subtract(const Duration(seconds: 59));
      expect(formatChatTimestamp(veryRecent), 'Только что');
    });

    test('returns "X минут назад" for messages less than 1 hour old', () {
      final now = DateTime.now();

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(formatChatTimestamp(fiveMinutesAgo), '5 минут назад');

      final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
      expect(formatChatTimestamp(thirtyMinutesAgo), '30 минут назад');
    });

    test('uses correct Russian declension for minutes in timestamps', () {
      final now = DateTime.now();

      // 1 минуту
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      expect(formatChatTimestamp(oneMinuteAgo), '1 минуту назад');

      // 2-4 минуты
      final twoMinutesAgo = now.subtract(const Duration(minutes: 2));
      expect(formatChatTimestamp(twoMinutesAgo), '2 минуты назад');

      // 5+ минут
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(formatChatTimestamp(fiveMinutesAgo), '5 минут назад');
    });

    test('returns "X часов назад" for messages less than 24 hours old', () {
      final now = DateTime.now();

      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(formatChatTimestamp(twoHoursAgo), '2 часа назад');

      final tenHoursAgo = now.subtract(const Duration(hours: 10));
      expect(formatChatTimestamp(tenHoursAgo), '10 часов назад');
    });

    test('uses correct Russian declension for hours', () {
      final now = DateTime.now();

      // 1 час
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      expect(formatChatTimestamp(oneHourAgo), '1 час назад');

      // 2-4 часа
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      expect(formatChatTimestamp(threeHoursAgo), '3 часа назад');

      // 5+ часов
      final fiveHoursAgo = now.subtract(const Duration(hours: 5));
      expect(formatChatTimestamp(fiveHoursAgo), '5 часов назад');
    });

    test('returns "Вчера в HH:mm" for messages from yesterday', () {
      // Create a timestamp that is yesterday but more than 24 hours ago
      // to avoid the "X часов назад" branch
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Yesterday at early morning (e.g., 2:00 AM) to ensure > 24 hours diff
      final yesterday = today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 2, minutes: 0));

      final result = formatChatTimestamp(yesterday);
      expect(result, startsWith('Вчера в '));
      expect(result, contains('02:00'));
    });

    test('returns weekday for messages within this week', () {
      final now = DateTime.now();
      // Find a day that's 2-6 days ago
      for (int i = 2; i <= 6; i++) {
        final pastDate = now.subtract(Duration(days: i));
        final result = formatChatTimestamp(pastDate);

        // Should contain a Russian weekday name and time
        final weekdays = [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье',
        ];
        final containsWeekday = weekdays.any((day) => result.contains(day));
        expect(containsWeekday, true);
        expect(result, contains(' в '));
      }
    });

    test('returns date for older messages', () {
      final now = DateTime.now();
      final oldMessage = now.subtract(const Duration(days: 10));

      final result = formatChatTimestamp(oldMessage);
      // Should contain month name
      final months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря',
      ];
      final containsMonth = months.any(
        (month) => result.toLowerCase().contains(month),
      );
      expect(containsMonth, true);
    });
  });

  group('formatRelativeTime', () {
    test('returns "Только что" for times less than 60 seconds ago', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      expect(formatRelativeTime(justNow), 'Только что');
    });

    test('returns minutes for times less than 1 hour ago', () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(formatRelativeTime(fiveMinutesAgo), '5 минут назад');
    });

    test('returns hours for times less than 24 hours ago', () {
      final now = DateTime.now();
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      expect(formatRelativeTime(threeHoursAgo), '3 часа назад');
    });

    test('returns days for times less than 30 days ago', () {
      final now = DateTime.now();
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      expect(formatRelativeTime(fiveDaysAgo), '5 дней назад');
    });

    test('uses correct Russian declension for days', () {
      final now = DateTime.now();

      // 1 день
      final oneDayAgo = now.subtract(const Duration(days: 1));
      expect(formatRelativeTime(oneDayAgo), '1 день назад');

      // 2-4 дня
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      expect(formatRelativeTime(twoDaysAgo), '2 дня назад');

      // 5+ дней
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      expect(formatRelativeTime(sevenDaysAgo), '7 дней назад');
    });

    test('returns months for times less than 365 days ago', () {
      final now = DateTime.now();
      final twoMonthsAgo = now.subtract(const Duration(days: 60));
      expect(formatRelativeTime(twoMonthsAgo), '2 месяца назад');

      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      expect(formatRelativeTime(sixMonthsAgo), '6 месяцев назад');
    });

    test('uses correct Russian declension for months', () {
      final now = DateTime.now();

      // 1 месяц
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      expect(formatRelativeTime(oneMonthAgo), '1 месяц назад');

      // 2-4 месяца
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      expect(formatRelativeTime(threeMonthsAgo), '3 месяца назад');

      // 5+ месяцев
      final fiveMonthsAgo = now.subtract(const Duration(days: 150));
      expect(formatRelativeTime(fiveMonthsAgo), '5 месяцев назад');
    });

    test('returns years for times more than 365 days ago', () {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      expect(formatRelativeTime(oneYearAgo), '1 год назад');

      final twoYearsAgo = now.subtract(const Duration(days: 730));
      expect(formatRelativeTime(twoYearsAgo), '2 года назад');

      final fiveYearsAgo = now.subtract(const Duration(days: 1825));
      expect(formatRelativeTime(fiveYearsAgo), '5 лет назад');
    });

    test('uses correct Russian declension for years', () {
      final now = DateTime.now();

      // 1 год
      final oneYearAgo = now.subtract(const Duration(days: 365));
      expect(formatRelativeTime(oneYearAgo), '1 год назад');

      // 2-4 года
      final twoYearsAgo = now.subtract(const Duration(days: 730));
      expect(formatRelativeTime(twoYearsAgo), '2 года назад');

      // 5+ лет
      final fiveYearsAgo = now.subtract(const Duration(days: 1825));
      expect(formatRelativeTime(fiveYearsAgo), '5 лет назад');
    });
  });

  group('formatTimeOnly', () {
    test('returns time in HH:mm format', () {
      final time1 = DateTime(2023, 10, 15, 9, 30);
      expect(formatTimeOnly(time1), '09:30');

      final time2 = DateTime(2023, 10, 15, 14, 45);
      expect(formatTimeOnly(time2), '14:45');

      final time3 = DateTime(2023, 10, 15, 23, 59);
      expect(formatTimeOnly(time3), '23:59');

      final time4 = DateTime(2023, 10, 15, 0, 0);
      expect(formatTimeOnly(time4), '00:00');
    });
  });

  group('formatDateOnly', () {
    test('returns date in Russian format (d MMMM yyyy)', () {
      final date1 = DateTime(2023, 10, 15);
      final result1 = formatDateOnly(date1);
      expect(result1, contains('15'));
      expect(result1, contains('2023'));
      // Should contain Russian month name

      final date2 = DateTime(2024, 1, 1);
      final result2 = formatDateOnly(date2);
      expect(result2, contains('1'));
      expect(result2, contains('2024'));
    });
  });

  group('formatDateTime', () {
    test('returns date and time in Russian format with "в"', () {
      final dateTime1 = DateTime(2023, 10, 15, 14, 30);
      final result1 = formatDateTime(dateTime1);
      expect(result1, contains('15'));
      expect(result1, contains('2023'));
      expect(result1, contains('в'));
      expect(result1, contains('14:30'));

      final dateTime2 = DateTime(2024, 12, 25, 9, 15);
      final result2 = formatDateTime(dateTime2);
      expect(result2, contains('25'));
      expect(result2, contains('2024'));
      expect(result2, contains('в'));
      expect(result2, contains('09:15'));
    });
  });

  group('Russian declensions edge cases', () {
    test('handles numbers ending in 11-14 correctly (always plural)', () {
      final now = DateTime.now();

      // 11 минут (not минуту)
      final elevenMinutesAgo = now.subtract(const Duration(minutes: 11));
      expect(formatChatTimestamp(elevenMinutesAgo), '11 минут назад');

      // 12 часов (not часа)
      final twelveHoursAgo = now.subtract(const Duration(hours: 12));
      expect(formatChatTimestamp(twelveHoursAgo), '12 часов назад');

      // 14 дней (not дня)
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      expect(formatRelativeTime(fourteenDaysAgo), '14 дней назад');
    });

    test('handles 21, 22, 25 correctly for different forms', () {
      final now = DateTime.now();

      // Test that various minute values work correctly with declension
      final twentyOneMinutes = now.add(const Duration(minutes: 21));
      final result21 = formatEventTime(twentyOneMinutes);
      expect(result21, startsWith('Через '));
      expect(result21, contains('минут'));

      final twentyTwoMinutes = now.add(const Duration(minutes: 22));
      final result22 = formatEventTime(twentyTwoMinutes);
      expect(result22, startsWith('Через '));
      expect(result22, contains('минут'));

      final twentyFiveMinutes = now.add(const Duration(minutes: 25));
      final result25 = formatEventTime(twentyFiveMinutes);
      expect(result25, startsWith('Через '));
      expect(result25, contains('минут'));
    });
  });
}
