import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_fixed_app/main.dart';

void main() {
  // Setup Firebase for testing
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock Firebase initialization for tests
  });

  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HostelApp());

    // Verify that the app starts with splash screen
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const HostelApp());
    
    expect(find.text('Hostel Gate Pass'), findsOneWidget);
  });

  testWidgets('App uses MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(const HostelApp());
    
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}