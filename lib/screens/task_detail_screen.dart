import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(taskToEdit: _currentTask),
      ),
    );

    if (result == 'updated' && mounted) {
      // Refresh the task from provider
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final updatedTask = provider.tasks.firstWhere(
        (t) => t.id == _currentTask.id,
        orElse: () => _currentTask,
      );
      setState(() {
        _currentTask = updatedTask;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarefa atualizada com sucesso!',
              style: GoogleFonts.inter(color: AppTheme.textWhite)),
          backgroundColor: AppTheme.primaryNeon,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Excluir Tarefa',
            style: GoogleFonts.inter(color: AppTheme.textWhite)),
        content: Text('Tem certeza que deseja excluir esta tarefa?',
            style: GoogleFonts.inter(color: AppTheme.textBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppTheme.textBody)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir',
                style: GoogleFonts.inter(color: AppTheme.primaryNeon)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Provider.of<TaskProvider>(context, listen: false)
          .deleteTask(_currentTask.id);
      Navigator.pop(context, 'deleted');
    }
  }

  void _duplicateTask() {
    Provider.of<TaskProvider>(context, listen: false).duplicateTask(_currentTask.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tarefa duplicada!',
            style: GoogleFonts.inter(color: AppTheme.textWhite)),
        backgroundColor: AppTheme.primaryNeon,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Detalhes da Tarefa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.textWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.textWhite),
            onPressed: _duplicateTask,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.primaryNeon),
            onPressed: _deleteTask,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.secondaryNeon),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _currentTask.isDone
                    ? AppTheme.activeGreen.withOpacity(0.1)
                    : AppTheme.primaryNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _currentTask.isDone
                      ? AppTheme.activeGreen.withOpacity(0.5)
                      : AppTheme.primaryNeon.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentTask.isDone
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    color: _currentTask.isDone
                        ? AppTheme.activeGreen
                        : AppTheme.primaryNeon,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _currentTask.isDone ? 'Concluída' : 'Pendente',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Info
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentTask.title,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentTask.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textBody,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Due Date & Priority
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today,
                            color: AppTheme.secondaryNeon, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prazo Limite',
                            style: GoogleFonts.inter(
                              color: AppTheme.textBody,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy \'às\' HH:mm', 'pt_BR')
                                .format(_currentTask.dueDate),
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppTheme.backgroundDark, height: 1),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flag,
                          color: _currentTask.priority == 'Alta'
                              ? AppTheme.primaryNeon
                              : _currentTask.priority == 'Média'
                                  ? Colors.orange
                                  : AppTheme.textBody,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prioridade',
                            style: GoogleFonts.inter(
                              color: AppTheme.textBody,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentTask.priority,
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppTheme.backgroundDark, height: 1),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentTask.category == 'Trabalho' ? Icons.work :
                          _currentTask.category == 'Estudo' ? Icons.book :
                          _currentTask.category == 'Pessoal' ? Icons.person : Icons.category,
                          color: AppTheme.secondaryNeon,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoria',
                            style: GoogleFonts.inter(
                              color: AppTheme.textBody,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentTask.category,
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppTheme.backgroundDark, height: 1),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.repeat, color: AppTheme.textWhite, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repetição',
                            style: GoogleFonts.inter(
                              color: AppTheme.textBody,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentTask.recurrence,
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Checklist
            if (_currentTask.checklist.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentTask.checklist.length,
                      itemBuilder: (context, index) {
                        final item = _currentTask.checklist[index];
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              color: item.isDone ? AppTheme.textBody : AppTheme.textWhite,
                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          value: item.isDone,
                          activeColor: AppTheme.primaryNeon,
                          checkColor: AppTheme.backgroundDark,
                          onChanged: (bool? val) {
                            if (val != null) {
                              final updatedChecklist = List<ChecklistItem>.from(_currentTask.checklist);
                              updatedChecklist[index] = item.copyWith(isDone: val);
                              final updatedTask = _currentTask.copyWith(checklist: updatedChecklist);
                              Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
                              setState(() {
                                _currentTask = updatedTask;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            // Timestamps info
            Center(
              child: Text(
                'Criada em ${DateFormat('dd MMM yyyy HH:mm', 'pt_BR').format(_currentTask.createdAt)}\nÚltima atualização em ${DateFormat('dd MMM yyyy HH:mm', 'pt_BR').format(_currentTask.updatedAt)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textBody.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
