class HabitItem {
  const HabitItem({
    required this.title,
    required this.category,
    required this.target,
    required this.completed,
    this.streak = 0,
  });

  final String title;
  final String category;
  final int target;
  final int completed;
  final int streak;

  bool get isDone => completed >= target;

  int get percent {
    if (target <= 0) return 0;
    final value = ((completed / target) * 100).round();
    return value.clamp(0, 100);
  }

  HabitItem copyWith({
    String? title,
    String? category,
    int? target,
    int? completed,
    int? streak,
  }) {
    return HabitItem(
      title: title ?? this.title,
      category: category ?? this.category,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      streak: streak ?? this.streak,
    );
  }
}
