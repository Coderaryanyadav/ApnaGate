import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/app_routes.dart';

void main() {
  test('AppRoutes definitions are unique and formatted', () {
    final routes = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.authWrapper,
      AppRoutes.adminDashboard,
      AppRoutes.userManagement,
      AppRoutes.noticeAdmin,
      AppRoutes.analytics,
      AppRoutes.complaints,
      AppRoutes.serviceProviders,
      AppRoutes.patrolLogs,
      AppRoutes.guardHome,
      AppRoutes.addVisitor,
      AppRoutes.scanPass,
      AppRoutes.visitorStatus,
      AppRoutes.staffEntry,
      AppRoutes.patrol,
      AppRoutes.residentHome,
      AppRoutes.approval,
      AppRoutes.visitorHistory,
      AppRoutes.guestPass,
      AppRoutes.myPass,
      AppRoutes.household,
      AppRoutes.househelp,
      AppRoutes.notices,
      AppRoutes.complaintList,
      AppRoutes.serviceDirectory,
      AppRoutes.sos,
    ];

    final uniqueRoutes = routes.toSet();
    expect(uniqueRoutes.length, routes.length, reason: 'All routes must have unique paths');
    for (final route in routes) {
      expect(route.startsWith('/'), isTrue, reason: 'Route $route should start with /');
    }
  });
}
