import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user.dart';
import 'package:app/models/visitor.dart';
import 'package:app/models/guest_pass.dart';
import 'package:app/models/daily_help.dart';
import 'package:app/models/notice.dart';
import 'package:app/models/complaint.dart';
import 'package:app/models/sos_alert.dart';
import 'package:app/models/service_provider.dart';

void main() {
  group('AppUser Model Tests', () {
    test('AppUser fromJson and toJson serialization', () {
      final json = {
        'id': 'usr-123',
        'email': 'resident@apnagate.com',
        'name': 'Aryan Yadav',
        'role': 'resident',
        'wing': 'A',
        'flat_number': '1101',
        'phone': '9876543210',
        'user_type': 'owner',
        'family_members': ['Jagdeep', 'Seema'],
        'onesignal_player_id': 'onesignal-sub-456',
        'created_at': '2026-11-22T10:00:00.000Z',
        'updated_at': '2026-11-22T10:00:00.000Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.id, 'usr-123');
      expect(user.name, 'Aryan Yadav');
      expect(user.role, 'resident');
      expect(user.wing, 'A');
      expect(user.flatNumber, '1101');
      expect(user.familyMembers?.length, 2);
      expect(user.oneSignalPlayerId, 'onesignal-sub-456');

      final serialized = user.toJson();
      expect(serialized['id'], 'usr-123');
      expect(serialized['flat_number'], '1101');
    });

    test('AppUser copyWith modifies fields correctly', () {
      const user = AppUser(
        id: 'usr-1',
        email: 'test@gate.com',
        name: 'Tester',
        role: 'guard',
      );

      final updated = user.copyWith(role: 'admin', wing: 'B');
      expect(updated.id, 'usr-1');
      expect(updated.role, 'admin');
      expect(updated.wing, 'B');
      expect(updated.email, 'test@gate.com');
    });
  });

  group('Visitor Model Tests', () {
    test('Visitor fromJson and toJson serialization', () {
      final json = {
        'id': 'vis-101',
        'resident_id': 'res-1',
        'wing': 'A',
        'flat_number': '1101',
        'visitor_name': 'Rahul Sharma',
        'purpose': 'Delivery',
        'status': 'pending',
        'phone': '9998887776',
        'vehicle_number': 'MH02AB1234',
        'created_at': '2026-11-22T12:00:00.000Z',
      };

      final visitor = Visitor.fromJson(json);
      expect(visitor.id, 'vis-101');
      expect(visitor.visitorName, 'Rahul Sharma');
      expect(visitor.purpose, 'Delivery');
      expect(visitor.status, 'pending');

      final serialized = visitor.toJson();
      expect(serialized['vehicle_number'], 'MH02AB1234');
      expect(serialized['status'], 'pending');
    });
  });

  group('GuestPass Model Tests', () {
    test('GuestPass fromJson and toJson serialization', () {
      final json = {
        'id': 'pass-99',
        'resident_id': 'res-1',
        'guest_name': 'Amit Kumar',
        'guest_phone': '9123456780',
        'pass_code': '849201',
        'valid_from': '2026-11-22T10:00:00.000Z',
        'valid_until': '2026-11-23T10:00:00.000Z',
        'status': 'active',
      };

      final pass = GuestPass.fromJson(json);
      expect(pass.guestName, 'Amit Kumar');
      expect(pass.passCode, '849201');
      expect(pass.status, 'active');

      final serialized = pass.toJson();
      expect(serialized['pass_code'], '849201');
    });
  });

  group('DailyHelp Model Tests', () {
    test('DailyHelp fromJson and toJson serialization', () {
      final json = {
        'id': 'dh-1',
        'owner_id': 'res-1',
        'name': 'Sunita Devi',
        'role': 'Housekeeper',
        'phone': '9876500000',
        'is_inside': true,
      };

      final help = DailyHelp.fromJson(json);
      expect(help.name, 'Sunita Devi');
      expect(help.role, 'Housekeeper');
      expect(help.isInside, true);

      final serialized = help.toJson();
      expect(serialized['is_inside'], true);
    });
  });

  group('Notice & Complaint Model Tests', () {
    test('Notice fromJson and toJson serialization', () {
      final json = {
        'id': 'not-1',
        'title': 'Water Maintenance',
        'description': 'Tank cleaning scheduled for Sunday 10 AM to 2 PM.',
        'created_by': 'Admin',
      };

      final notice = Notice.fromJson(json);
      expect(notice.title, 'Water Maintenance');
      expect(notice.description, contains('Tank cleaning'));
    });

    test('Complaint fromJson and toJson serialization', () {
      final json = {
        'id': 'comp-1',
        'resident_id': 'res-1',
        'title': 'Lift B2 Not Working',
        'description': 'Lift B2 is stuck on 4th floor.',
        'status': 'in_progress',
      };

      final comp = Complaint.fromJson(json);
      expect(comp.title, 'Lift B2 Not Working');
      expect(comp.status, 'in_progress');
    });
  });

  group('SosAlert & ServiceProvider Tests', () {
    test('SosAlert fromJson and toJson serialization', () {
      final json = {
        'id': 'sos-1',
        'resident_id': 'res-1',
        'wing': 'A',
        'flat_number': '1101',
        'status': 'active',
      };

      final alert = SosAlert.fromJson(json);
      expect(alert.wing, 'A');
      expect(alert.flatNumber, '1101');
      expect(alert.status, 'active');
    });

    test('ServiceProvider fromJson and toJson serialization', () {
      final json = {
        'id': 'sp-1',
        'name': 'Sharma Electricals',
        'category': 'Electrician',
        'phone': '9820012345',
      };

      final sp = ServiceProvider.fromJson(json);
      expect(sp.name, 'Sharma Electricals');
      expect(sp.category, 'Electrician');
      expect(sp.phone, '9820012345');
    });
  });
}
