import 'package:flutter/material.dart';
import 'package:proyecto_teo_info/features/tasks/data/models/task.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key, required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No hay tareas aún.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = tasks[index];
        final due = t.dueDate != null
            ? 'Vence: ${t.dueDate!.toLocal()}'
            : 'Sin fecha';
        return ListTile(
          leading: const Icon(Icons.check_box_outline_blank),
          title: Text(t.title),
          subtitle: Text(
            t.notes?.isNotEmpty == true ? '${t.notes}\n$due' : due,
          ),
          isThreeLine: t.notes?.isNotEmpty == true,
        );
      },
    );
  }
}
