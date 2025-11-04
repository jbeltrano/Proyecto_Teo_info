class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime? dueDate;

  Task({required this.id, required this.title, this.notes, this.dueDate});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id:
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Tarea',
    notes: json['notes'] as String?,
    dueDate: json['due_date'] != null
        ? DateTime.tryParse(json['due_date'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'due_date': dueDate?.toIso8601String(),
  };
}
