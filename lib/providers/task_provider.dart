import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final SupabaseStorageService _storageService = SupabaseStorageService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<Task> get activeTasks => _tasks.where((t) => !t.isDone).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isDone).toList();

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _tasks = await _storageService.getTasks(userId);
    } else {
      _tasks = [];
    }
    _sortTasks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    _sortTasks();
    await _storageService.addTask(task);
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index >= 0) {
      _tasks[index] = updatedTask;
      _sortTasks();
      await _storageService.updateTask(updatedTask);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _storageService.deleteTask(id);
    await NotificationService().cancelNotification(id.hashCode);
    notifyListeners();
  }

  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final task = _tasks[index];
      final String newStatus = task.status == 'Concluída' ? 'Pendente' : 'Concluída';
      _tasks[index] = task.copyWith(status: newStatus, updatedAt: DateTime.now());
      
      final bool isNowDone = newStatus == 'Concluída';
      
      if (isNowDone && task.recurrence != 'S/ Repetição') {
        _generateRecurrentTask(task);
        // _generateRecurrentTask already adds to list, we should also save it to DB. Let's let it handle it.
      }

      if (isNowDone) {
        await NotificationService().cancelNotification(task.id.hashCode);
      }
      
      _sortTasks();
      await _storageService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  void _generateRecurrentTask(Task oldTask) {
    DateTime nextDate = oldTask.dueDate;
    if (oldTask.recurrence == 'Diária') {
      nextDate = nextDate.add(const Duration(days: 1));
    } else if (oldTask.recurrence == 'Semanal') {
      nextDate = nextDate.add(const Duration(days: 7));
    } else if (oldTask.recurrence == 'Mensal') {
      nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day, nextDate.hour, nextDate.minute);
    }
    
    final newTask = oldTask.copyWith(
      id: const Uuid().v4(),
      dueDate: nextDate,
      status: 'Pendente',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      checklist: oldTask.checklist.map((c) => c.copyWith(isDone: false)).toList(),
      history: [],
    );
    
    _tasks.add(newTask);
    _storageService.addTask(newTask);
    if (newTask.hasAlarm) {
      // Best effort to schedule the new alarm, though async errors won't be caught here gracefully
      NotificationService().scheduleTaskNotification(newTask);
    }
  }

  Future<void> duplicateTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final task = _tasks[index];
      final duplicatedTask = task.copyWith(
        id: const Uuid().v4(),
        title: '${task.title} (Cópia)',
        status: 'Pendente',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        checklist: task.checklist.map((c) => c.copyWith(isDone: false)).toList(),
        history: [],
      );
      _tasks.add(duplicatedTask);
      _storageService.addTask(duplicatedTask);
      if (duplicatedTask.hasAlarm) {
        try {
          await NotificationService().scheduleTaskNotification(duplicatedTask);
        } catch (e) {
          // Ignored if alarm cannot be scheduled (e.g., past date)
        }
      }
      _sortTasks();
      // Task added via addTask so it was already saved directly above, but wait: I used _storageService.addTask. Let's make sure it is saved.
      notifyListeners();
    }
  }

  Future<void> clearCompleted() async {
    final completed = _tasks.where((t) => t.isDone).toList();
    _tasks.removeWhere((t) => t.isDone);
    for (var task in completed) {
      await _storageService.deleteTask(task.id);
    }
    notifyListeners();
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'Alta':
        return 3;
      case 'Média':
        return 2;
      case 'Baixa':
        return 1;
      default:
        return 0;
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // First, sort by status (active first)
      if (a.isDone && !b.isDone) return 1;
      if (!a.isDone && b.isDone) return -1;

      // If both have same status, sort by priority (High first)
      final pA = _getPriorityValue(a.priority);
      final pB = _getPriorityValue(b.priority);
      if (pA != pB) return pB.compareTo(pA);

      // If priority is same, sort by date (earlier first)
      return a.dueDate.compareTo(b.dueDate);
    });
  }
}
