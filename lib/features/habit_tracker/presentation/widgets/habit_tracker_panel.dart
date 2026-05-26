import 'package:flutter/material.dart';

import '../../domain/habit_item.dart';

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
      ),
      const HabitItem(
        title: 'Workout 30 minutes',
        category: 'Health',
        target: 1,
        completed: 0,
      ),
      const HabitItem(
        title: 'Study Flutter',
        category: 'Skill',
        target: 1,
        completed: 0,
      ),
      const HabitItem(
        title: 'Plan tomorrow',
        category: 'Productivity',
        target: 1,
        completed: 0,
      ),
    ];
  }

  int get completedCount {
    return habits.where((habit) => habit.isDone).length;
  }

  int get progress {
    if (habits.isEmpty) return 0;
    return ((completedCount / habits.length) * 100).round();
  }

  void toggleHabit(int index) {
    final habit = habits[index];

    setState(() {
      habits[index] = HabitItem(
        title: habit.title,
        category: habit.category,
        target: habit.target,
        completed: habit.isDone ? 0 : habit.target,
      );
    });
  }

  void resetHabits() {
    setState(() {
      habits = habits.map((habit) {
        return HabitItem(
          title: habit.title,
          category: habit.category,
          target: habit.target,
          completed: 0,
        );
      }).toList();
    });
  }

  void completeAllHabits() {
    setState(() {
      habits = habits.map((habit) {
        return HabitItem(
          title: habit.title,
          category: habit.category,
          target: habit.target,
          completed: habit.target,
        );
      }).toList();
    });
  }

  Future<void> addHabit() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
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
                const Text(
                  'ADD NEW HABIT',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Example: Drink water',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
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
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallButton(
                        text: 'Add',
                        filled: true,
                        onTap: () {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          Navigator.pop(context, text);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (value == null || value.trim().isEmpty) return;

    setState(() {
      habits.add(
        HabitItem(
          title: value.trim(),
          category: 'Custom',
          target: 1,
          completed: 0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HABIT TRACKER',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap any habit to update today progress.',
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
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(value: progress),
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
                if (index != habits.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFE0E0E0),
                  ),
              ],
            );
          }),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: habit.isDone
                    ? const Color(0xFF111111)
                    : const Color(0xFFEDEDED),
                child: habit.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
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
                      habit.category,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                habit.isDone ? 'Done' : 'Pending',
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final factor = (value / 100).clamp(0.0, 1.0);

    return Container(
      height: 8,
      width: double.infinity,
      color: const Color(0xFFEDEDED),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: factor,
        child: Container(height: 8, color: const Color(0xFF111111)),
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
          height: 38,
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
