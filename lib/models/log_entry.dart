enum LogMood { excellent, good, normal, bad }

class LogEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;
  final LogMood mood;

  LogEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.tags,
    required this.mood,
  });
}
