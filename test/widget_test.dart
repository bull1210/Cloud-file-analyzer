import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudvault_analyzer/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CloudVaultApp()),
    );
    // App needs OAuth accounts to show content; verify it doesn't crash on launch.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
