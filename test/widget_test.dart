// Widget tests for Findora
//
// Tests verify that the main app shell can be built and key navigation
// elements are present. Full integration tests require a connected device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_stuff_ai/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FindoraApp(),
      ),
    );
    // Allow async providers to settle
    await tester.pump(const Duration(milliseconds: 100));

    // The app should render some widget tree
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MaterialApp has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FindoraApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, equals('Findora'));
  });
}
