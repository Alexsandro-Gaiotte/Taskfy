import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'supabase_config.dart';

class SupabaseStorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Task>> getTasks(String userId) async {
    try {
      // Pega tarefas criadas pelo user ou atribuídas/compartilhadas com ele
      final response = await _client
          .from('tasks')
          .select()
          .or('createdBy.eq.$userId,assignedTo.cs.["$userId"],sharedWith.cs.["$userId"]');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar tarefas do Supabase: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    // Isso deve idealmente ser feito fazendo upsert de cada uma.
    for (var task in tasks) {
      await addTask(task);
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _client.from('tasks').upsert(task.toMap());
    } catch (e) {
      print('Erro ao adicionar tarefa no Supabase: $e');
      throw Exception('Falha ao salvar tarefa no Supabase.');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _client.from('tasks').update(task.toMap()).eq('id', task.id);
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
    }
  }
}
