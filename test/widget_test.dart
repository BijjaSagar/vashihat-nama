// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vasihat_nama/main.dart';

void main() {
  testWidgets('App renders SecureLoginScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the SecureLoginScreen title is present.
    expect(find.text('Vasihat Nama'), findsOneWidget);
    expect(find.text('Zero-Knowledge Secure Vault'), findsOneWidget);
    
    // Verify icons are present
    expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
  });
}
