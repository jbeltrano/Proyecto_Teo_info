DateTime? _parseLocal(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  final d = DateTime.tryParse(s);
  if (d == null) return null;
  // Si viene en UTC -> pásalo a local. Si ya es local, respétalo.
  return d.isUtc ? d.toLocal() : d;
}

// Acepta ISO 8601 con/ sin hora y normaliza a local
DateTime? _parseDueDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    // Solo fecha -> medianoche local
    final parts = s.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
  final d = DateTime.tryParse(s);
  if (d == null) return null;
  return d.isUtc ? d.toLocal() : d;
}

class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final bool done;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueDate,
    this.done = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? dueDate,
    bool? done,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    dueDate: dueDate ?? this.dueDate,
    done: done ?? this.done,
  );

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id:
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: (json['title'] ?? '').toString(),
    notes: json['notes'] as String?,
    // Acepta 'due_date' (IA/DB) o 'dueDate' (posible variante)
    dueDate: _parseDueDate(json['due_date'] ?? json['dueDate']),
    done: (json['done'] is bool)
        ? json['done'] as bool
        : (json['done'] is int ? (json['done'] == 1) : false),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    // Persistimos con 'due_date'
    'due_date': dueDate?.toIso8601String(),
    'done': done,
  };
}
