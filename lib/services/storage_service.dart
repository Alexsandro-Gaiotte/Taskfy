import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'tasks';

  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);

    if (tasksJson == null) {
      return [];
    }

    final List<dynamic> decodedList = json.decode(tasksJson);
    return decodedList.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapList =
        tasks.map((task) => task.toMap()).toList();
    final String tasksJson = json.encode(mapList);

    await prefs.setString(_tasksKey, tasksJson);
  }

  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }
}
