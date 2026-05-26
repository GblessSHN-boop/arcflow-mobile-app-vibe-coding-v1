import 'package:flutter/material.dart';

import '../../domain/habit_item.dart';

class HabitTrackerSnapshot {
  const HabitTrackerSnapshot({
    required this.total,
    required this.completed,
    required this.progress,
    required this.bestHabit,
  });

  final int total;
  final int completed;
  final int progress;
  final String bestHabit;
}

final ValueNotifier<HabitTrackerSnapshot> habitTrackerStatsNotifier =
    ValueNotifier<HabitTrackerSnapshot>(
      const HabitTrackerSnapshot(
        total: 4,
        completed: 1,
        progress: 25,
        bestHabit: 'Read 20 pages',
      ),
    );

class HabitTrackerPanel extends StatefulWidget {
  const HabitTrackerPanel({super.key});

  @override
  State<HabitTrackerPanel> createState() => _HabitTrackerPanelState();
}

class _HabitTrackerPanelState extends State<HabitTrackerPanel> {
  late List<HabitItem> habits;

  @override
  void initState() {
    super.initState();
    habits = [
      const HabitItem(
        title: 'Read 20 pages',
        category: 'Learning',
        target: 1,
        completed: 1,
        streak: 4,
      ),
      const HabitItem(
        title: 'Workout 30 minutes',
        category: 'Health',
        target: 1,
        completed: 0,
        streak: 2,
      ),
      const HabitItem(
        title: 'Study Flutter',
        category: 'Skill',
        target: 1,
        completed: 0,
        streak: 3,
      ),
      const HabitItem(
        title: 'Plan tomorrow',
        category: 'Productivity',
        target: 1,
        completed: 0,
        streak: 1,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncStats();
    });
  }

  int get completedCount {
    return habits.where((habit) => habit.isDone).length;
  }

  int get progress {
    if (habits.isEmpty) return 0;
    return ((completedCount / habits.length) * 100).round();
  }

  String get bestHabit {
    if (habits.isEmpty) return 'No habit yet';

    final doneHabits = habits.where((habit) => habit.isDone).toList();
    if (doneHabits.isNotEmpty) {
      doneHabits.sort((a, b) => b.streak.compareTo(a.streak));
      return doneHabits.first.title;
    }

    final sorted = [...habits]..sort((a, b) => b.streak.compareTo(a.streak));
    return sorted.first.title;
  }

  void syncStats() {
    habitTrackerStatsNotifier.value = HabitTrackerSnapshot(
      total: habits.length,
      completed: completedCount,
      progress: progress,
      bestHabit: bestHabit,
    );
  }

  void toggleHabit(int index) {
    final habit = habits[index];

    setState(() {
      habits[index] = habit.copyWith(
        completed: habit.isDone ? 0 : habit.target,
        streak: habit.isDone ? habit.streak : habit.streak + 1,
      );
      syncStats();
    });
  }

  void resetHabits() {
    setState(() {
      habits = habits.map((habit) {
        return habit.copyWith(completed: 0);
      }).toList();
      syncStats();
    });
  }

  void completeAllHabits() {
    setState(() {
      habits = habits.map((habit) {
        return habit.copyWith(
          completed: habit.target,
          streak: habit.streak + 1,
        );
      }).toList();
      syncStats();
    });
  }

  Future<void> addHabit() async {
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return const _AddHabitDialog();
      },
    );

    if (!mounted) return;
    if (value == null || value.trim().isEmpty) return;

    setState(() {
      habits.add(
        HabitItem(
          title: value.trim(),
          category: 'Custom',
          target: 1,
          completed: 0,
          streak: 0,
        ),
      );
      syncStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _HabitPanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('HABIT TRACKER'),
          const SizedBox(height: 6),
          const Text(
            'Tap a habit to update progress.',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumberText(value: progress, fontSize: 42, suffix: '%'),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Text(
                    '$completedCount of ${habits.length} habits completed today.',
                    style: const TextStyle(
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
          const SizedBox(height: 12),
          AnimatedProgressBar(value: progress),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SmallButton(
                  text: 'Add Habit',
                  filled: true,
                  onTap: addHabit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallButton(
                  text: 'Complete All',
                  filled: false,
                  onTap: completeAllHabits,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallButton(
                  text: 'Reset',
                  filled: false,
                  onTap: resetHabits,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(habits.length, (index) {
            final habit = habits[index];

            return Column(
              children: [
                _HabitRow(habit: habit, onTap: () => toggleHabit(index)),
                if (index != habits.length - 1) const _DividerLine(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
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
                  const _SectionLabel('ADD NEW HABIT'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: const Color(0xFF111111),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: const InputDecoration(
                      hintText: 'Example: Drink water',
                      hintStyle: TextStyle(
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w600,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFD6D6D6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFF111111)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallButton(
                          text: 'Cancel',
                          filled: false,
                          onTap: cancel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SmallButton(
                          text: 'Add',
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

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.onTap});

  final HabitItem habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFEDEDED),
        highlightColor: const Color(0xFFEDEDED),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: habit.isDone ? 0.82 : 1.08, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 22,
                      height: 22,
                      color: habit.isDone
                          ? const Color(0xFF111111)
                          : const Color(0xFFEDEDED),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: habit.isDone
                            ? const Icon(
                                Icons.check,
                                key: ValueKey('checked'),
                                color: Colors.white,
                                size: 16,
                              )
                            : const SizedBox(key: ValueKey('empty')),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.category} | ${habit.streak} day streak',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  habit.isDone ? 'Done' : 'Pending',
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedNumberText extends StatelessWidget {
  const AnimatedNumberText({
    super.key,
    required this.value,
    required this.fontSize,
    this.suffix = '',
  });

  final int value;
  final double fontSize;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$animatedValue$suffix',
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        );
      },
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final factor = (value / 100).clamp(0.0, 1.0);

    return Container(
      height: 9,
      width: double.infinity,
      color: const Color(0xFFEDEDED),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: factor),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        builder: (context, widthFactor, child) {
          return FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(height: 9, color: const Color(0xFF111111)),
          );
        },
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFF111111),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitPanelShell extends StatelessWidget {
  const _HabitPanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFE0E0E0),
    );
  }
}
