import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_mate/controllers/health_controller.dart';
import 'package:health_mate/models/health_record.dart';
import 'package:health_mate/utils/formatters.dart';
import 'package:health_mate/views/main_navigation_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_health_repository.dart';

Future<HealthController> pumpApp(
  WidgetTester tester,
  FakeHealthRepository repo, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final controller = HealthController(repository: repo);
  await controller.loadRecords();

  await tester.pumpWidget(
    ChangeNotifierProvider<HealthController>.value(
      value: controller,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const MainNavigationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

FakeHealthRepository sampleRepo() => FakeHealthRepository(
  records: [
    HealthRecord(date: daysAgo(1), steps: 9120, calories: 510, waterMl: 2250),
    HealthRecord(date: daysAgo(0), steps: 5000, calories: 300, waterMl: 1500),
    HealthRecord(date: daysAgo(0), steps: 2850, calories: 120, waterMl: 500),
  ],
);

Future<void> openRecordsTab(WidgetTester tester) async {
  await tester.tap(find.text('Records'));
  await tester.pumpAndSettle();
}

Future<void> fillForm(
  WidgetTester tester, {
  required String steps,
  required String calories,
  required String water,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(1), steps);
  await tester.enterText(fields.at(2), calories);
  await tester.enterText(fields.at(3), water);
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save Record'));
  await tester.tap(find.text('Save Record'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows today\'s date and summed totals', (
    tester,
  ) async {
    final controller = await pumpApp(tester, sampleRepo());

    expect(
      find.text(
        'Today – ${AppFormatters.longDate(controller.todayDateString)}',
      ),
      findsOneWidget,
    );
    expect(find.text('7,850'), findsOneWidget);
    expect(find.text('420'), findsOneWidget);
    expect(find.text('2,000'), findsOneWidget);
    expect(find.text('Goal: 8,000 steps'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
  });

  testWidgets('record list shows every record with readable dates', (
    tester,
  ) async {
    await pumpApp(tester, sampleRepo());
    await openRecordsTab(tester);

    expect(find.text('Health Records'), findsOneWidget);
    expect(find.text('All logged daily activities (3)'), findsOneWidget);
    expect(find.text(AppFormatters.cardDate(daysAgo(1))), findsOneWidget);
    expect(find.text('9,120 steps'), findsOneWidget);
  });

  testWidgets('saving an empty form shows a validation error', (tester) async {
    final repo = sampleRepo();
    await pumpApp(tester, repo);
    await openRecordsTab(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add Health Record'), findsOneWidget);

    await tapSave(tester);

    expect(
      find.text('Steps must be a valid non-negative number.'),
      findsOneWidget,
    );
    expect(repo.stored, hasLength(3));
  });

  testWidgets('number fields only accept digits', (tester) async {
    await pumpApp(tester, sampleRepo());
    await openRecordsTab(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '12a-3.4');
    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('adding a valid record saves it and shows it in the list', (
    tester,
  ) async {
    final repo = sampleRepo();
    await pumpApp(tester, repo);
    await openRecordsTab(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await fillForm(tester, steps: '4321', calories: '210', water: '750');
    await tapSave(tester);

    expect(find.text('Health record saved.'), findsOneWidget);
    expect(find.text('Health Records'), findsOneWidget);
    expect(find.text('4,321 steps'), findsOneWidget);
    expect(repo.stored, hasLength(4));
  });

  testWidgets('editing a record updates the values shown', (tester) async {
    await pumpApp(tester, sampleRepo());
    await openRecordsTab(tester);

    await tester.tap(find.byTooltip('Edit record').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Health Record'), findsOneWidget);
    expect(find.text('2850'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '9999');
    await tapSave(tester);

    expect(find.text('Record updated.'), findsOneWidget);
    expect(find.text('9,999 steps'), findsOneWidget);
    expect(find.text('2,850 steps'), findsNothing);
  });

  testWidgets('deleting asks for confirmation and removes the record', (
    tester,
  ) async {
    final repo = sampleRepo();
    await pumpApp(tester, repo);
    await openRecordsTab(tester);

    await tester.tap(find.byTooltip('Delete record').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Record'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.stored, hasLength(3));

    await tester.tap(find.byTooltip('Delete record').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Record deleted.'), findsOneWidget);
    expect(repo.stored, hasLength(2));
    expect(find.text('All logged daily activities (2)'), findsOneWidget);
  });

  testWidgets('filtering by date shows only matching records', (tester) async {
    final controller = await pumpApp(tester, sampleRepo());
    await openRecordsTab(tester);

    controller.filterByDate(daysAgo(1));
    await tester.pumpAndSettle();
    expect(
      find.text('Showing records for ${AppFormatters.longDate(daysAgo(1))}'),
      findsOneWidget,
    );
    expect(find.text('9,120 steps'), findsOneWidget);
    expect(find.text('5,000 steps'), findsNothing);

    controller.filterByDate('2020-01-01');
    await tester.pumpAndSettle();
    expect(find.text('No records found for 1 January 2020.'), findsOneWidget);

    await tester.tap(find.text('Show All Dates'));
    await tester.pumpAndSettle();
    expect(find.text('All logged daily activities (3)'), findsOneWidget);
  });

  testWidgets('goals dialog rejects zero and saves new goals', (tester) async {
    final repo = sampleRepo();
    await pumpApp(tester, repo);

    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Health Goals'), findsOneWidget);

    final goalFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(goalFields.at(0), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Each goal must be greater than 0.'), findsOneWidget);

    await tester.enterText(goalFields.at(0), '10000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.goals.stepsGoal, 10000);
    expect(find.text('Goal: 10,000 steps'), findsOneWidget);
    expect(find.text('79%'), findsOneWidget);
  });

  testWidgets('screens still fit at 150% system font size', (tester) async {
    await pumpApp(tester, sampleRepo(), textScale: 1.5);
    expect(find.text('Dashboard'), findsOneWidget);

    await openRecordsTab(tester);
    expect(find.text('2,850 steps'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add Health Record'), findsOneWidget);
  });
}
