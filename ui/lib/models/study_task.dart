class StudyTask {
  const StudyTask({
    required this.title,
    required this.caption,
    required this.minutes,
    required this.completed,
  });

  final String title;
  final String caption;
  final int minutes;
  final bool completed;
}
