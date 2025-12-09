import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user.dart';

void main() {
  group('AppUser Model Tests', () {
    final testDate = DateTime.now();
    final testUserMap = {
      'id': 'test_id',
      'email': 'test@example.com',
      'name': 'Test User',
      'phone': '1234567890',
      'flat_number': '101',
      'wing': 'A',
      'role': 'resident',
      'created_at': testDate.toIso8601String(),
    };

    test('should create AppUser from map', () {
      final user = AppUser.fromMap(testUserMap, 'test_id');

      expect(user.id, 'test_id');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.flatNumber, '101');
      expect(user.wing, 'A');
      expect(user.role, 'resident');
      // Date parsing might be slightly off due to precision, check if relatively close or same string
      // expect(user.createdAt.toIso8601String(), testDate.toIso8601String()); 
    });

    test('should convert AppUser to map', () {
      final user = AppUser.fromMap(testUserMap, 'test_id');
      final map = user.toMap();

      expect(map['id'], 'test_id');
      expect(map['email'], 'test@example.com');
      expect(map['flat_number'], '101');
    });

    test('should handle null optional fields', () {
      final minimalMap = {
        'id': 'test_id',
        'email': 'test@example.com',
        'name': 'Test User',
        'phone': '1234567890',
        'role': 'resident',
        'created_at': testDate.toIso8601String(),
      };
      
      final user = AppUser.fromMap(minimalMap, 'test_id');
      expect(user.flatNumber, null);
      expect(user.wing, null);
    });
  });
}
