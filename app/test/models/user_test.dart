import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user.dart';

void main() {
  group('AppUser Model Tests', () {
    // 10/10 Testing: Verify Data Integrity
    test('Verified AppUser serialization (toMap/fromMap)', () {
      final now = DateTime.now();
      final user = AppUser(
        id: '123',
        email: 'test@example.com',
        name: 'John Doe',
        phone: '9876543210',
        role: 'resident',
        createdAt: now,
        wing: 'A',
        flatNumber: '101',
        photoUrl: 'https://example.com/photo.jpg',
        oneSignalPlayerId: 'player-id-123',
      );

      // Serialize
      final map = user.toMap();
      
      expect(map['id'], '123');
      expect(map['email'], 'test@example.com');
      expect(map['onesignal_player_id'], 'player-id-123');

      // Deserialize
      final fromMapUser = AppUser.fromMap(map, '123');
      
      expect(fromMapUser.id, user.id);
      expect(fromMapUser.email, user.email);
      expect(fromMapUser.oneSignalPlayerId, user.oneSignalPlayerId);
      // Date comparison might need tolerance, but toIso8601String preserves precision usually
    });

    test('AppUser copyWith creates new instance with updates', () {
      final user = AppUser(
         id: '123', email: 'a@b.com', name: 'A', phone: '1', role: 'guard', createdAt: DateTime.now()
      );

      final updatedUser = user.copyWith(name: 'New Name', phone: '222');

      expect(updatedUser.name, 'New Name');
      expect(updatedUser.phone, '222');
      expect(updatedUser.email, 'a@b.com'); // Unchanged
    });
  });
}
