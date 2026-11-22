import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/error_boundary.dart';

void main() {
  testWidgets('ErrorBoundary renders normal child when no error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ErrorBoundary(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Normal App Content'),
        ),
      ),
    );

    expect(find.text('Normal App Content'), findsOneWidget);
  });
}
