import 'package:flutter/material.dart';

import '../../../habit_tracker/presentation/widgets/habit_tracker_panel.dart';

class DashboardActivitySnapshot {
  const DashboardActivitySnapshot({
    required this.quickNotes,
    required this.savedTasks,
    required this.dailyReviews,
    required this.todayPoints,
    required this.lastAction,
  });

  final int quickNotes;
  final int savedTasks;
  final int dailyReviews;
  final int todayPoints;
  final String lastAction;

  int get totalActions => quickNotes + savedTasks + dailyReviews;

  DashboardActivitySnapshot copyWith({
    int? quickNotes,
    int? savedTasks,
    int? dailyReviews,
    int? todayPoints,
    String? lastAction,
  }) {
    return DashboardActivitySnapshot(
      quickNotes: quickNotes ?? this.quickNotes,
      savedTasks: savedTasks ?? this.savedTasks,
      dailyReviews: dailyReviews ?? this.dailyReviews,
      todayPoints: todayPoints ?? this.todayPoints,
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

final ValueNotifier<DashboardActivitySnapshot> dashboardActivityNotifier =
    ValueNotifier<DashboardActivitySnapshot>(
      const DashboardActivitySnapshot(
        quickNotes: 0,
        savedTasks: 0,
        dailyReviews: 0,
        todayPoints: 0,
        lastAction: 'No action yet',
      ),
    );

class DashboardEntry extends StatelessWidget {
  const DashboardEntry({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('dashboard-entry-$order'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 720 + (order * 110)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 26),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class LiveTodayScoreCard extends StatelessWidget {
  const LiveTodayScoreCard({super.key});

  int _score(HabitTrackerSnapshot habit, DashboardActivitySnapshot activity) {
    final actionBonus = activity.todayPoints.clamp(0, 20);
    final score = habit.progress + actionBonus;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HabitTrackerSnapshot>(
      valueListenable: habitTrackerStatsNotifier,
      builder: (context, habit, child) {
        return ValueListenableBuilder<DashboardActivitySnapshot>(
          valueListenable: dashboardActivityNotifier,
          builder: (context, activity, child) {
            final score = _score(habit, activity);

            return DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardLabel('TODAY SCORE'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedNumberText(
                        value: score,
                        fontSize: 48,
                        suffix: '%',
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Live score from habit completion and daily actions.',
                            style: TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedProgressBar(value: score),
                  const SizedBox(height: 12),
                  _ScoreLine(
                    title:
                        '${habit.completed} of ${habit.total} habits completed',
                    value: '${habit.progress}%',
                  ),
                  const SizedBox(height: 8),
                  _ScoreLine(
                    title: '${activity.totalActions} quick actions recorded',
                    value: '+${activity.todayPoints.clamp(0, 20)}',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class LiveQuickActions extends StatelessWidget {
  const LiveQuickActions({super.key});

  void _recordQuickNote() {
    final current = dashboardActivityNotifier.value;
    dashboardActivityNotifier.value = current.copyWith(
      quickNotes: current.quickNotes + 1,
      todayPoints: current.todayPoints + 5,
      lastAction: 'Quick note saved',
    );
  }

  void _recordTask() {
    final current = dashboardActivityNotifier.value;
    dashboardActivityNotifier.value = current.copyWith(
      savedTasks: current.savedTasks + 1,
      todayPoints: current.todayPoints + 7,
      lastAction: 'Task saved',
    );
  }

  void _recordReview() {
    final current = dashboardActivityNotifier.value;
    dashboardActivityNotifier.value = current.copyWith(
      dailyReviews: current.dailyReviews + 1,
      todayPoints: current.todayPoints + 8,
      lastAction: 'Daily review checked',
    );
  }

  Future<void> _openInput(
    BuildContext context, {
    required String title,
    required String hint,
    required VoidCallback onSaved,
    required String successMessage,
  }) async {
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _DashboardInputDialog(title: title, hint: hint);
      },
    );

    if (!context.mounted) return;
    if (value == null || value.trim().isEmpty) return;

    onSaved();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openReview(BuildContext context) {
    _recordReview();

    final habit = habitTrackerStatsNotifier.value;
    final activity = dashboardActivityNotifier.value;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _DashboardReviewDialog(habit: habit, activity: activity);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBox(
            icon: Icons.note_add,
            text: 'Quick Note',
            onTap: () {
              _openInput(
                context,
                title: 'QUICK NOTE',
                hint: 'Write a short note',
                onSaved: _recordQuickNote,
                successMessage: 'Quick note saved',
              );
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionBox(
            icon: Icons.task_alt,
            text: 'Add Task',
            onTap: () {
              _openInput(
                context,
                title: 'ADD TASK',
                hint: 'Example: Finish report',
                onSaved: _recordTask,
                successMessage: 'Task saved',
              );
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionBox(
            icon: Icons.fact_check,
            text: 'Check Today',
            onTap: () => _openReview(context),
          ),
        ),
      ],
    );
  }
}

class _DashboardInputDialog extends StatefulWidget {
  const _DashboardInputDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_DashboardInputDialog> createState() => _DashboardInputDialogState();
}

class _DashboardInputDialogState extends State<_DashboardInputDialog> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.unfocus();
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(text);
  }

  void cancel() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF111111), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardLabel(widget.title),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    cursorColor: const Color(0xFF111111),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFD6D6D6)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFF111111)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardDialogButton(
                          text: 'Cancel',
                          filled: false,
                          onTap: cancel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DashboardDialogButton(
                          text: 'Save',
                          filled: true,
                          onTap: submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardReviewDialog extends StatelessWidget {
  const _DashboardReviewDialog({required this.habit, required this.activity});

  final HabitTrackerSnapshot habit;
  final DashboardActivitySnapshot activity;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardLabel('DAILY REVIEW'),
            const SizedBox(height: 12),
            Text(
              '${habit.completed} of ${habit.total} habits completed today.',
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick notes: ${activity.quickNotes} | Tasks: ${activity.savedTasks} | Reviews: ${activity.dailyReviews}',
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Strongest habit: ${habit.bestHabit}',
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            DashboardDialogButton(
              text: 'Close',
              filled: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFEDEDED),
        highlightColor: const Color(0xFFEDEDED),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF111111), size: 22),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContributionsLastYearCard extends StatelessWidget {
  const ContributionsLastYearCard({super.key});

  static const int columns = 53;
  static const int rows = 7;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HabitTrackerSnapshot>(
      valueListenable: habitTrackerStatsNotifier,
      builder: (context, habit, child) {
        return ValueListenableBuilder<DashboardActivitySnapshot>(
          valueListenable: dashboardActivityNotifier,
          builder: (context, activity, child) {
            return DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardLabel('CONTRIBUTIONS IN THE LAST YEAR'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(columns, (weekIndex) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: weekIndex == columns - 1 ? 0 : 4,
                          ),
                          child: Column(
                            children: List.generate(rows, (dayIndex) {
                              final level = _levelForDay(
                                weekIndex: weekIndex,
                                dayIndex: dayIndex,
                                habit: habit,
                                activity: activity,
                              );

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: dayIndex == rows - 1 ? 0 : 4,
                                ),
                                child: AnimatedContainer(
                                  duration: Duration(
                                    milliseconds:
                                        180 + ((weekIndex + dayIndex) % 8) * 18,
                                  ),
                                  curve: Curves.easeOut,
                                  width: 11,
                                  height: 11,
                                  color: _shade(level),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Today updates from habits and quick actions. A new day adds a new square automatically.',
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _levelForDay({
    required int weekIndex,
    required int dayIndex,
    required HabitTrackerSnapshot habit,
    required DashboardActivitySnapshot activity,
  }) {
    final todayRaw = DateTime.now();
    final today = DateTime(todayRaw.year, todayRaw.month, todayRaw.day);
    final startDate = today.subtract(const Duration(days: columns * rows - 1));
    final date = startDate.add(Duration(days: weekIndex * rows + dayIndex));

    if (_sameDay(date, today)) {
      final raw = ((habit.progress + activity.todayPoints).clamp(0, 100) / 25)
          .ceil();
      return raw.clamp(0, 4).toInt();
    }

    if (date.isAfter(today)) return 0;

    final seed = ((date.day * 31) + (date.month * 17) + date.weekday) % 8;

    if (seed <= 2) return 0;
    if (seed == 3) return 1;
    if (seed == 4 || seed == 5) return 2;
    if (seed == 6) return 3;
    return 4;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _shade(int value) {
    if (value <= 0) return const Color(0xFFEDEDED);
    if (value == 1) return const Color(0xFFCFCFCF);
    if (value == 2) return const Color(0xFF9E9E9E);
    if (value == 3) return const Color(0xFF555555);
    return const Color(0xFF111111);
  }
}

class LiveInsightCard extends StatelessWidget {
  const LiveInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HabitTrackerSnapshot>(
      valueListenable: habitTrackerStatsNotifier,
      builder: (context, habit, child) {
        return ValueListenableBuilder<DashboardActivitySnapshot>(
          valueListenable: dashboardActivityNotifier,
          builder: (context, activity, child) {
            return DashboardPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Color(0xFF111111),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        'Strongest habit today: ${habit.bestHabit}. Last action: ${activity.lastAction}. Keep today clean and finish one priority task next.',
                        key: ValueKey(
                          '${habit.bestHabit}-${activity.lastAction}-${activity.todayPoints}',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: child,
    );
  }
}

class DashboardLabel extends StatelessWidget {
  const DashboardLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class DashboardDialogButton extends StatelessWidget {
  const DashboardDialogButton({
    super.key,
    required this.text,
    required this.filled,
    required this.onTap,
  });

  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF111111) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF111111), width: 1),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFF111111),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
