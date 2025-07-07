// File: test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/main.dart';

void main() {
  testWidgets('App loads and shows LoginScreen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(TravelApp());

    // Verify LoginScreen is shown by checking for text 'Welcome Back!'
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Verify Login button is present
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Tap on 'Don\'t have an account? Register' button and verify navigation
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle();

    // Check Register screen loads
    expect(find.text('Create Account'), findsOneWidget);

    // Tap on 'Already have an account? Login' to go back
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle();

    // Back to Login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
