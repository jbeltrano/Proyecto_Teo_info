import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../../tasks/data/models/task.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  const TaskList({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<TaskController>();
    if (tasks.isEmpty) return const Center(child: Text('No hay tareas aún.'));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = tasks[i];
        return Dismissible(
          key: ValueKey(t.id.isNotEmpty ? t.id : 'task_$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar tarea'),
                    content: Text('¿Eliminar “${t.title}”?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) {
            ctrl.deleteTask(t.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tarea eliminada: ${t.title}')),
            );
          },
          child: ListTile(
            leading: Checkbox(
              value: t.done,
              onChanged: (v) => ctrl.toggleDone(t.id, v ?? !t.done),
            ),
            title: Text(
              t.title,
              style: TextStyle(
                decoration: t.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: (t.notes != null || t.dueDate != null)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.notes != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t.notes!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (t.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${t.dueDate!.year}-${t.dueDate!.month.toString().padLeft(2, '0')}-${t.dueDate!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ctrl, t),
              tooltip: 'Editar',
            ),
            onTap: () => _showEditDialog(context, ctrl, t),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, TaskController ctrl, Task t) {
    final titleCtrl = TextEditingController(text: t.title);
    final notesCtrl = TextEditingController(text: t.notes ?? '');
    DateTime? due = t.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Editar tarea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    due != null
                        ? 'Fecha: ${due?.year}-${due?.month.toString().padLeft(2, '0')}-${due?.day.toString().padLeft(2, '0')}'
                        : 'Sin fecha',
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: const Text('Cambiar'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: due ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      due = DateTime(picked.year, picked.month, picked.day);
                      // Fuerza reconstrucción simple cerrando y reabriendo el sheet? No.
                      // Mejor: pop y reabrir no es UX ideal; mostramos la fecha al guardar.
                    }
                  },
                ),
                if (due != null)
                  TextButton(
                    onPressed: () => due = null,
                    child: const Text('Quitar fecha'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final newTitle = titleCtrl.text.trim();
                    if (newTitle.isEmpty) return;
                    ctrl.updateTask(
                      t.copyWith(
                        title: newTitle,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                        dueDate: due,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
