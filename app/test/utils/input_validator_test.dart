import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/input_validator.dart';

void main() {
  group('InputValidator Tests', () {
    
    test('sanitizeText removes harmful chars', () {
      const input = '<script>alert("xss")</script> Hello';
      final output = InputValidator.sanitizeText(input);
      expect(output, 'scriptalert("xss")/script Hello'); // Basic regex removes < >
    });

    test('validateEmail returns error for invalid email', () {
      expect(InputValidator.validateEmail('invalid'), 'Enter a valid email address');
      expect(InputValidator.validateEmail(''), 'Email is required');
      expect(InputValidator.validateEmail(null), 'Email is required');
    });

    test('validateEmail returns null for valid email', () {
      expect(InputValidator.validateEmail('test@example.com'), null);
    });

    test('validatePhone enforces length', () {
      expect(InputValidator.validatePhone('123'), 'Phone number must be at least 10 digits');
      expect(InputValidator.validatePhone('1234567890'), null);
    });

    test('validateName allows valid names', () {
      expect(InputValidator.validateName('John Doe'), null);
      expect(InputValidator.validateName('Jane-Doe'), null);
      expect(InputValidator.validateName('User123'), 'Name can only contain letters, spaces, hyphens, and periods');
    });

    test('containsSQLInjection detects patterns', () {
      expect(InputValidator.containsSQLInjection('SELECT * FROM users'), true);
      expect(InputValidator.containsSQLInjection('DROP TABLE users'), true);
      expect(InputValidator.containsSQLInjection('Normal text'), false);
    });
    
    test('containsXSS detects patterns', () {
      expect(InputValidator.containsXSS('<script>alert(1)</script>'), true);
      expect(InputValidator.containsXSS('javascript:void(0)'), true);
      expect(InputValidator.containsXSS('Hello World'), false);
    });
  });
}
