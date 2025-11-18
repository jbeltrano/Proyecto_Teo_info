class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueDate,
    this.isCompleted = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id:
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Tarea',
    notes: json['notes'] as String?,
    dueDate: json['due_date'] != null
        ? DateTime.tryParse(json['due_date'])
        : null,
    isCompleted: json['is_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'due_date': dueDate?.toIso8601String(),
    'is_completed': isCompleted,
  };

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
