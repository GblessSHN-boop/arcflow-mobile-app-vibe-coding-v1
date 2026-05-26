class HabitItem {
  const HabitItem({
    required this.title,
    required this.category,
    required this.target,
    required this.completed,
  });

  final String title;
  final String category;
  final int target;
  final int completed;

  bool get isDone => completed >= target;

  int get percent {
    if (target <= 0) return 0;
    final value = ((completed / target) * 100).round();
    return value.clamp(0, 100);
  }
}
