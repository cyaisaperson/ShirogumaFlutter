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
    expect(find.text('Bluetooth Disconnected'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Battery --'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('DEVICE'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Browse devices'), findsOneWidget);
    expect(find.text('DEVICE'), findsOneWidget);
    expect(find.text('XIAO nRF52840'), findsOneWidget);
    expect(find.text('Live saving:'), findsOneWidget);
    expect(find.text('Blocked: BLE disconnected'), findsOneWidget);
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

  testWidgets('settings page exposes mode storage and sync controls', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Data mode'), findsOneWidget);
    expect(find.text('Live BLE'), findsWidgets);
    expect(find.text('SD Card Sync'), findsWidgets);
    await tester.tap(find.text('SD Card Sync').first);
    await tester.pumpAndSettle();

    expect(find.text('Battery characteristic UUID'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Stable window'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Stable window'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Local JSON storage'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Local JSON storage'), findsOneWidget);
    expect(find.text('Active patient'), findsOneWidget);
    expect(find.text('Anya Rahimi'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Coming later'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Coming later'), findsOneWidget);
    expect(find.text('Clear local database'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(find.text('SD'), findsOneWidget);
    expect(find.text('Battery --'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('DEVICE'), 300);
    await tester.pumpAndSettle();
    expect(find.text('DEVICE'), findsOneWidget);
  });

  testWidgets('clear local database asks for confirmation', (tester) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear local database'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local database'));
    await tester.pumpAndSettle();

    expect(find.text('Clear local database?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Clear data'), findsOneWidget);
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
    expect(find.text('Latest pain level'), findsNothing);
    expect(find.text('Total events'), findsNothing);
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
    await tester.pumpAndSettle();
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

    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-open-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-timeline-graph')), findsOneWidget);
    expect(find.text('Selected pain event'), findsOneWidget);
    expect(find.text('Wong-Baker face image placeholder'), findsOneWidget);
    expect(find.byKey(const ValueKey('patient-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('patient-graph-card')), findsNothing);
    expect(find.text('Total events'), findsNothing);
    expect(find.text('Latest pain level'), findsNothing);
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

    final bubble = find.byKey(const ValueKey('pain-bubble-event-anya-today-1'));
    await tester.ensureVisible(bubble);
    await tester.pumpAndSettle();
    await tester.tap(bubble);
    await tester.pumpAndSettle();

    final summaryTop = tester
        .getTopLeft(find.byKey(const ValueKey('patient-summary-card')))
        .dy;
    final graphTop = tester
        .getTopLeft(find.byKey(const ValueKey('bubble-timeline-graph')))
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

    expect(find.text('Selected pain event'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pain-bubble-event-marcus-today-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pain-bubble-event-marcus-week-1')),
      findsNothing,
    );
    expect(find.byTooltip('Previous range'), findsOneWidget);
    expect(find.byTooltip('Next range'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Previous range'), findsOneWidget);
    expect(find.byTooltip('Next range'), findsOneWidget);
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
    'same-day mock bubbles show readable pain levels and hourly labels',
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
      expect(find.text('0:00'), findsWidgets);
      expect(find.text('6:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('08:10'), findsNothing);
      expect(find.text('17:40'), findsNothing);
    },
  );

  testWidgets('timeline axis switches by day week month and year tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcus Tate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    expect(find.text('0:00'), findsWidgets);
    expect(find.text('6:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('10:45'), findsNothing);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/'), findsWidgets);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
    expect(find.text('12'), findsWidgets);
    expect(find.text('10:45'), findsNothing);
  });

  testWidgets('calendar controls share the range row above the graph', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    final calendarButton = find.byKey(const ValueKey('calendar-open-button'));
    final rangeSelector = find.byKey(const ValueKey('timeline-range-selector'));
    final graph = find.byKey(const ValueKey('bubble-timeline-graph'));

    expect(calendarButton, findsOneWidget);
    expect(rangeSelector, findsOneWidget);
    expect(graph, findsOneWidget);
    expect(tester.getSize(graph).height, greaterThanOrEqualTo(215));
    expect(
      tester.getTopLeft(calendarButton).dy,
      lessThan(tester.getTopLeft(graph).dy),
    );
    expect(
      tester.getTopLeft(rangeSelector).dy,
      lessThan(tester.getTopLeft(calendarButton).dy),
    );
  });

  testWidgets('timeline tabs and day axis labels keep even spacing', (
    tester,
  ) async {
    await tester.pumpWidget(const ShirogumaApp());

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anya Rahimi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').last);
    await tester.pumpAndSettle();

    final dayCenter = tester.getCenter(find.text('Day'));
    final weekCenter = tester.getCenter(find.text('Week'));
    final monthCenter = tester.getCenter(find.text('Month'));
    final yearCenter = tester.getCenter(find.text('Year'));
    final tabGaps = [
      weekCenter.dx - dayCenter.dx,
      monthCenter.dx - weekCenter.dx,
      yearCenter.dx - monthCenter.dx,
    ];

    for (final gap in tabGaps) {
      expect(gap, closeTo(tabGaps.first, 2));
    }

    final axisCenters = [
      tester.getCenter(find.text('0:00').at(0)).dx,
      tester.getCenter(find.text('6:00')).dx,
      tester.getCenter(find.text('12:00')).dx,
      tester.getCenter(find.text('18:00')).dx,
      tester.getCenter(find.text('0:00').at(1)).dx,
    ];
    final axisGaps = [
      for (var index = 1; index < axisCenters.length; index += 1)
        axisCenters[index] - axisCenters[index - 1],
    ];

    for (final gap in axisGaps) {
      expect(gap, closeTo(axisGaps.first, 2));
    }
  });

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

    final previousDay = find.byTooltip('Previous range');
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
