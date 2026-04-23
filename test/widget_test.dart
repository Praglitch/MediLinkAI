import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medilink_ai/src/widgets/app_header.dart';

void main() {
  testWidgets('AppHeader renders title and subtitle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHeader(
            title: 'Dashboard',
            subtitle: 'Overview of resources',
          ),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Overview of resources'), findsOneWidget);
  });
}
