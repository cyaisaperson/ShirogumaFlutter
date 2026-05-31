import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/app.dart';

void main() {
  testWidgets('renders the Shiroguma app shell', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    expect(find.text('Shiroguma Squeeze'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Patients'), findsWidgets);
    expect(find.text('Data'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('bottom navigation switches between primary pages', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    expect(find.text('Patient roster'), findsOneWidget);

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();
    expect(find.text('Patient Data'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Device settings'), findsOneWidget);
  });

  testWidgets('patients page displays mock patients', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();

    expect(find.text('Anya Rahimi'), findsOneWidget);
    expect(find.text('Marcus Tate'), findsOneWidget);
    expect(find.text('Joud Karam'), findsOneWidget);
  });

  testWidgets('selecting a patient updates active patient views', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcus Tate'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Marcus Tate'), findsOneWidget);
    expect(find.textContaining('P-002'), findsOneWidget);

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();
    expect(find.text('Marcus Tate'), findsOneWidget);
    expect(find.text('Latest pain level'), findsOneWidget);
  });

  testWidgets('adds a patient from the patients page dialog', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add patient'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Mina Chen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Patient ID'),
      'P-004',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '9');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes'),
      'Needs a quiet room for calibration.',
    );
    await tester.tap(find.text('Save patient'));
    await tester.pumpAndSettle();

    expect(find.text('Mina Chen'), findsOneWidget);
    expect(find.textContaining('P-004'), findsOneWidget);
  });

  testWidgets('edits an existing patient from the patients page dialog', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Anya Sato',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Anya Sato'), findsOneWidget);
    expect(find.text('Anya Rahimi'), findsNothing);
  });

  testWidgets('home quick actions switch to main sections', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Manage patients'));
    await tester.pumpAndSettle();
    expect(find.text('Patient roster'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open data'));
    await tester.pumpAndSettle();
    expect(find.text('Patient Data'), findsOneWidget);
  });
}
