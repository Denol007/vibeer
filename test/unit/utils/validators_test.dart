import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/core/utils/validators.dart';

void main() {
  group('validateAge', () {
    test('returns error for null age', () {
      expect(validateAge(null), 'Укажите возраст');
    });

    test('returns error for age < 18', () {
      expect(validateAge(0), 'Вам должно быть не менее 18 лет');
      expect(validateAge(10), 'Вам должно быть не менее 18 лет');
      expect(validateAge(17), 'Вам должно быть не менее 18 лет');
    });

    test('returns null for valid age 18-25', () {
      expect(validateAge(18), null);
      expect(validateAge(20), null);
      expect(validateAge(22), null);
      expect(validateAge(25), null);
    });

    test('returns error for age > 25', () {
      expect(validateAge(26), 'Вам должно быть не более 25 лет');
      expect(validateAge(30), 'Вам должно быть не более 25 лет');
      expect(validateAge(100), 'Вам должно быть не более 25 лет');
    });
  });

  group('validateEventTime', () {
    test('returns error for null time', () {
      expect(validateEventTime(null), 'Укажите время начала');
    });

    test('returns error for past time', () {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
      expect(
        validateEventTime(pastTime),
        'Время начала не может быть в прошлом',
      );
    });

    test('returns error for time less than 5 minutes away', () {
      final tooSoon = DateTime.now().add(const Duration(minutes: 2));
      expect(validateEventTime(tooSoon), 'Минимум 5 минут до начала');
    });

    test('returns null for valid time (5 minutes to 24 hours)', () {
      final fiveMinutes = DateTime.now().add(const Duration(minutes: 5));
      final oneHour = DateTime.now().add(const Duration(hours: 1));
      final twelveHours = DateTime.now().add(const Duration(hours: 12));
      final twentyThreeHours = DateTime.now().add(const Duration(hours: 23));

      expect(validateEventTime(fiveMinutes), null);
      expect(validateEventTime(oneHour), null);
      expect(validateEventTime(twelveHours), null);
      expect(validateEventTime(twentyThreeHours), null);
    });

    test('returns error for time more than 24 hours away', () {
      final tooFar = DateTime.now().add(const Duration(hours: 25));
      expect(
        validateEventTime(tooFar),
        'Событие должно начаться в течение 24 часов',
      );
    });

    test('edge case: exactly 5 minutes away', () {
      // Should be valid at exactly 5 minutes
      final exactlyFive = DateTime.now().add(
        const Duration(minutes: 5, seconds: 1),
      );
      expect(validateEventTime(exactlyFive), null);
    });

    test('edge case: exactly 24 hours away', () {
      // Should be valid at exactly 24 hours
      final exactly24 = DateTime.now().add(const Duration(hours: 24));
      expect(validateEventTime(exactly24), null);
    });
  });

  group('validateParticipants', () {
    test('returns error for null count', () {
      expect(validateParticipants(null), 'Укажите количество участников');
    });

    test('returns error for count < 1', () {
      expect(validateParticipants(0), 'Минимум 1 участник');
      expect(validateParticipants(-1), 'Минимум 1 участник');
    });

    test('returns null for valid count (1-5)', () {
      expect(validateParticipants(1), null);
      expect(validateParticipants(2), null);
      expect(validateParticipants(3), null);
      expect(validateParticipants(4), null);
      expect(validateParticipants(5), null);
    });

    test('returns error for count > 5', () {
      expect(validateParticipants(6), 'Максимум 5 участников');
      expect(validateParticipants(10), 'Максимум 5 участников');
    });
  });

  group('validateTextLength', () {
    test('returns error for null when minLength > 0', () {
      expect(validateTextLength(null, 100, minLength: 1), 'Поле обязательно');
      expect(
        validateTextLength(null, 100, minLength: 1, fieldName: 'Описание'),
        'Описание обязательно',
      );
    });

    test('returns null for null when minLength = 0', () {
      expect(validateTextLength(null, 100, minLength: 0), null);
      expect(validateTextLength('', 100, minLength: 0), null);
      expect(validateTextLength('   ', 100, minLength: 0), null);
    });

    test('returns error for text shorter than minLength', () {
      expect(
        validateTextLength('ab', 100, minLength: 5),
        'Поле должно содержать не менее 5 символов',
      );
      expect(
        validateTextLength('abc', 100, minLength: 10, fieldName: 'Имя'),
        'Имя должно содержать не менее 10 символов',
      );
    });

    test('returns null for text within valid length', () {
      expect(validateTextLength('Hello', 100, minLength: 3), null);
      expect(validateTextLength('Test message', 50, minLength: 5), null);
    });

    test('returns error for text longer than maxLength', () {
      expect(
        validateTextLength('Hello World', 5, minLength: 0),
        'Поле должно содержать не более 5 символов',
      );
      expect(
        validateTextLength(
          'This is too long',
          10,
          minLength: 0,
          fieldName: 'Описание',
        ),
        'Описание должно содержать не более 10 символов',
      );
    });

    test('trims whitespace before validation', () {
      expect(validateTextLength('  test  ', 10, minLength: 3), null);
      expect(
        validateTextLength('  a  ', 10, minLength: 3),
        'Поле должно содержать не менее 3 символов',
      );
    });
  });

  group('validateEmail', () {
    test('returns error for null email', () {
      expect(validateEmail(null), 'Укажите email');
    });

    test('returns error for empty email', () {
      expect(validateEmail(''), 'Укажите email');
      expect(validateEmail('   '), 'Укажите email');
    });

    test('returns error for invalid email formats', () {
      expect(validateEmail('invalid'), 'Неверный формат email');
      expect(validateEmail('invalid@'), 'Неверный формат email');
      expect(validateEmail('invalid@domain'), 'Неверный формат email');
      expect(validateEmail('@domain.com'), 'Неверный формат email');
      expect(validateEmail('user@'), 'Неверный формат email');
      expect(validateEmail('user domain@test.com'), 'Неверный формат email');
    });

    test('returns null for valid email formats', () {
      expect(validateEmail('test@example.com'), null);
      expect(validateEmail('user.name@domain.com'), null);
      expect(validateEmail('user+tag@example.co.uk'), null);
      expect(validateEmail('first.last@subdomain.example.com'), null);
      expect(validateEmail('user123@test-domain.org'), null);
    });

    test('trims whitespace before validation', () {
      expect(validateEmail('  test@example.com  '), null);
    });
  });

  group('validateRequired', () {
    test('returns error for null value', () {
      expect(validateRequired(null), 'Поле обязательно');
      expect(validateRequired(null, fieldName: 'Имя'), 'Имя обязательно');
    });

    test('returns error for empty string', () {
      expect(validateRequired(''), 'Поле обязательно');
      expect(validateRequired('', fieldName: 'Email'), 'Email обязательно');
    });

    test('returns error for whitespace-only string', () {
      expect(validateRequired('   '), 'Поле обязательно');
      expect(
        validateRequired('  \n  ', fieldName: 'Описание'),
        'Описание обязательно',
      );
    });

    test('returns null for non-empty string', () {
      expect(validateRequired('test'), null);
      expect(validateRequired('Hello World'), null);
      expect(validateRequired('  text  '), null); // has content after trim
    });
  });

  group('validateName', () {
    test('returns error for null name', () {
      expect(validateName(null), 'Укажите имя');
    });

    test('returns error for empty name', () {
      expect(validateName(''), 'Укажите имя');
      expect(validateName('   '), 'Укажите имя');
    });

    test('returns null for valid names', () {
      expect(validateName('Иван'), null);
      expect(validateName('Мария'), null);
      expect(validateName('John'), null);
      expect(validateName('Mary Jane'), null);
      expect(validateName("O'Brien"), null);
      expect(validateName('Jean-Pierre'), null);
      expect(validateName('Анна-Мария'), null);
      expect(validateName('Екатерина'), null);
    });

    test('returns error for name longer than 50 characters', () {
      final longName = 'A' * 51;
      expect(
        validateName(longName),
        'Имя должно содержать не более 50 символов',
      );
    });

    test('returns error for names with invalid characters', () {
      expect(
        validateName('John123'),
        'Имя может содержать только буквы, пробелы и дефисы',
      );
      expect(
        validateName('User@Name'),
        'Имя может содержать только буквы, пробелы и дефисы',
      );
      expect(
        validateName('Name!'),
        'Имя может содержать только буквы, пробелы и дефисы',
      );
      expect(
        validateName('User.Name'),
        'Имя может содержать только буквы, пробелы и дефисы',
      );
    });

    test('edge case: exactly 50 characters', () {
      final name50 = 'A' * 50;
      expect(validateName(name50), null);
    });

    test('trims whitespace before validation', () {
      expect(validateName('  Иван  '), null);
      expect(validateName('  John Doe  '), null);
    });
  });
}
