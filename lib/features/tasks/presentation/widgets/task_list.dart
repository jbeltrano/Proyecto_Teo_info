import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_teo_info/features/tasks/data/models/task.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/controllers/task_controller.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key, required this.tasks});

  final List<Task> tasks;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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
            ? 'Vence: ${_formatDate(t.dueDate!)}'
            : 'Sin fecha';
        final controller = context.read<TaskController>();
        
        return ListTile(
          leading: Checkbox(
            value: t.isCompleted,
            onChanged: (_) => controller.toggleTaskCompletion(t.id),
          ),
          title: Text(
            t.title,
            style: TextStyle(
              color: t.isCompleted ? Colors.black.withOpacity(0.4) : Colors.black,
              decoration: t.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            t.notes?.isNotEmpty == true ? '${t.notes}\n$due' : due,
            style: TextStyle(
              color: t.isCompleted ? Colors.black.withOpacity(0.4) : null,
            ),
          ),
          isThreeLine: t.notes?.isNotEmpty == true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => controller.deleteTask(t.id),
            tooltip: 'Eliminar tarea',
          ),
        );
      },
    );
  }
}
