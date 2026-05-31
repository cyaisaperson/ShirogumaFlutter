import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiroguma_squeeze_app/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Patient ID'),
          )
          .controller!
          .text,
      'P-004',
    );

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

  testWidgets('rejects duplicate patient IDs in patient dialog', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add patient'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Duplicate Patient',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Patient ID'),
      'P-001',
    );
    await tester.tap(find.text('Save patient'));
    await tester.pumpAndSettle();

    expect(find.text('Patient ID already exists'), findsOneWidget);
    expect(find.text('Save patient'), findsOneWidget);
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
    await tester.pumpAndSettle();

    final managePatients = find.text('Manage patients');
    await tester.scrollUntilVisible(managePatients, 300);
    await tester.pumpAndSettle();
    await tester.tap(managePatients);
    await tester.pumpAndSettle();
    expect(find.text('Patient roster'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    final openData = find.text('Open data');
    await tester.scrollUntilVisible(openData, 300);
    await tester.tap(openData);
    await tester.pumpAndSettle();
    expect(find.text('Patient Data'), findsOneWidget);
  });

  testWidgets('patient data page shows Phase 4 static sections', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    expect(find.text('1D'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-timeline-graph')), findsOneWidget);
    expect(find.text('Selected pain event'), findsNothing);
    expect(find.text('Wong-Baker face image placeholder'), findsNothing);
    expect(find.byKey(const ValueKey('patient-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('patient-graph-card')), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
  });

  testWidgets('patient data boxes follow requested order after bubble select', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pain-bubble-event-anya-today-1')),
    );
    await tester.pumpAndSettle();

    final summaryTop = tester
        .getTopLeft(find.byKey(const ValueKey('patient-summary-card')))
        .dy;
    final graphTop = tester
        .getTopLeft(find.byKey(const ValueKey('patient-graph-card')))
        .dy;
    final selectedTop = tester
        .getTopLeft(find.byKey(const ValueKey('selected-event-card')))
        .dy;

    expect(summaryTop, lessThan(graphTop));
    expect(graphTop, lessThan(selectedTop));
    expect(find.byKey(const ValueKey('patient-metrics-card')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('patient-summary-card')),
        matching: find.text('Baseline'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('patient-summary-card')),
        matching: find.text('MVS'),
      ),
      findsNothing,
    );
  });

  testWidgets('patient data timeline bubbles select event details', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcus Tate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    expect(find.text('Selected pain event'), findsNothing);
    expect(
      find.byKey(const ValueKey('pain-bubble-event-marcus-today-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pain-bubble-event-marcus-week-1')),
      findsNothing,
    );
    expect(find.byTooltip('Previous day'), findsOneWidget);
    expect(find.byTooltip('Next day'), findsOneWidget);

    await tester.tap(find.text('7D'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Previous day'), findsNothing);
    expect(find.byTooltip('Next day'), findsNothing);
    expect(
      find.byKey(const ValueKey('pain-bubble-event-marcus-week-1')),
      findsOneWidget,
    );

    final weekBubble = find.byKey(
      const ValueKey('pain-bubble-event-marcus-week-1'),
    );
    await tester.ensureVisible(weekBubble);
    await tester.pumpAndSettle();
    await tester.tap(weekBubble);
    await tester.pumpAndSettle();

    expect(find.text('Level 5'), findsWidgets);
    expect(find.text('91'), findsOneWidget);
  });

  testWidgets(
    'same-day mock bubbles show readable pain levels and time labels',
    (tester) async {
      await tester.pumpWidget(const ShirogumaApp());

      await tester.tap(find.text('Patients').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anya Rahimi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data').last);
      await tester.pumpAndSettle();

      final levelOneBubble = find.byKey(
        const ValueKey('pain-bubble-event-anya-today-level-1'),
      );
      final levelFiveBubble = find.byKey(
        const ValueKey('pain-bubble-event-anya-today-level-5'),
      );

      expect(levelOneBubble, findsOneWidget);
      expect(levelFiveBubble, findsOneWidget);
      expect(tester.getSize(levelOneBubble).width, greaterThanOrEqualTo(28));
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);
      expect(find.text('08:10'), findsOneWidget);
      expect(find.text('17:40'), findsOneWidget);
    },
  );

  testWidgets(
    'timeline axis switches from time labels to date labels by range',
    (tester) async {
      await tester.pumpWidget(const ShirogumaApp());

      await tester.tap(find.text('Patients').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcus Tate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data').last);
      await tester.pumpAndSettle();

      expect(find.text('10:45'), findsOneWidget);

      await tester.tap(find.text('7D'));
      await tester.pumpAndSettle();

      expect(find.text('10:45'), findsNothing);
      expect(find.textContaining('/'), findsWidgets);
    },
  );

  testWidgets('calendar highlights days with pain events', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    final calendarButton = find.byKey(const ValueKey('calendar-open-button'));
    await tester.ensureVisible(calendarButton);
    await tester.pumpAndSettle();
    await tester.tap(calendarButton);
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final todayKey =
        'calendar-day-with-event-${today.year}-${today.month}-${today.day}';
    expect(find.byKey(ValueKey(todayKey)), findsOneWidget);
  });

  testWidgets('one day range previous arrow changes visible events', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pain-bubble-event-anya-today-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pain-bubble-event-anya-yesterday-1')),
      findsNothing,
    );

    final previousDay = find.byTooltip('Previous day');
    await tester.ensureVisible(previousDay);
    await tester.pumpAndSettle();
    await tester.tap(previousDay);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pain-bubble-event-anya-today-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('pain-bubble-event-anya-yesterday-1')),
      findsOneWidget,
    );
  });

  testWidgets('manual calibration dialog saves active patient calibration', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Calibrate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calibrate'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Baseline pressure'),
      '1011',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'MVS pressure'),
      '2333',
    );
    await tester.tap(find.text('Save calibration'));
    await tester.pumpAndSettle();

    expect(find.text('2333 mbar'), findsWidgets);
  });
}
