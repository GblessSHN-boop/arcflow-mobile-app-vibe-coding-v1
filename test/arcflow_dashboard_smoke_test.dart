import 'package:arcflow/features/habit_tracker/presentation/widgets/habit_tracker_panel.dart';
import 'package:arcflow/features/main_dashboard/presentation/widgets/live_dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ARCFlow dashboard v1.2.2 smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  LiveTodayScoreCard(),
                  SizedBox(height: 12),
                  LiveQuickActions(),
                  SizedBox(height: 12),
                  HabitTrackerPanel(),
                  SizedBox(height: 12),
                  ContributionsLastYearCard(),
                  SizedBox(height: 12),
                  LiveInsightCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TODAY SCORE'), findsOneWidget);
    expect(find.text('Quick Note'), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
    expect(find.text('Check Today'), findsOneWidget);
    expect(find.text('HABIT TRACKER'), findsOneWidget);
    expect(find.text('CONTRIBUTIONS IN THE LAST YEAR'), findsOneWidget);

    await tester.tap(find.text('Quick Note'));
    await tester.pumpAndSettle();

    expect(find.text('QUICK NOTE'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Test quick note');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quick note saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();

    expect(find.text('ADD TASK'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Test task');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Task saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Check Today'));
    await tester.pumpAndSettle();

    expect(find.text('DAILY REVIEW'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Workout 30 minutes'));
    await tester.tap(find.text('Workout 30 minutes'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('2 of 4 habits completed'), findsWidgets);

    await tester.ensureVisible(find.text('Complete All'));
    await tester.tap(find.text('Complete All'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('4 of 4 habits completed'), findsWidgets);

    await tester.ensureVisible(find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('0 of 4 habits completed'), findsWidgets);
  });
}
