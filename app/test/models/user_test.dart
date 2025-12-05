import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AppUser Model', () {
    test('should correctly deserialize from Firestore map', () {
      final data = {
        'name': 'Test User',
        'phone': '1234567890',
        'flatNumber': '101',
        'wing': 'A',
        'role': 'resident',
        'userType': 'owner',
        'familyMembers': ['Wife', 'Son'],
        'createdAt': Timestamp.now(),
      };

      final user = AppUser.fromMap(data, 'uid_123');

      expect(user.uid, 'uid_123');
      expect(user.name, 'Test User');
      expect(user.wing, 'A');
      expect(user.familyMembers, contains('Son'));
      expect(user.role, 'resident');
    });

    test('should handle null optional fields', () {
      final data = {
        'name': 'Guard User',
        'phone': '0000',
        'role': 'guard',
        'createdAt': Timestamp.now(),
      };

      final user = AppUser.fromMap(data, 'uid_guard');

      expect(user.flatNumber, null);
      expect(user.wing, null);
      expect(user.familyMembers, null);
    });
  });
}
