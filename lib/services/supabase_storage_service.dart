import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'supabase_config.dart';

class SupabaseStorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Task>> getTasks(String userId) async {
    final List<dynamic> allTasks = [];
    
    // 1. Busca as tarefas criadas pelo usuário (Sempre deve funcionar)
    try {
      final resCreated = await _client.from('tasks').select().eq('createdBy', userId);
      allTasks.addAll(resCreated as List<dynamic>);
    } catch (e) {
      debugPrint('Erro ao buscar tarefas (createdBy): $e');
    }

    // Para colunas jsonb (assignedTo e sharedWith), o contains no Supabase Flutter
    // precisa receber a exata string JSON (ex: '["id"]') para não ser confundido
    // com um array Postgres normal (que usa chaves {}).
    final String jsonUserId = '["$userId"]';

    // 2. Busca as tarefas atribuídas ao usuário
    try {
      final resAssigned = await _client.from('tasks').select().contains('assignedTo', jsonUserId);
      allTasks.addAll(resAssigned as List<dynamic>);
    } catch (e) {
      debugPrint('Erro ao buscar tarefas (assignedTo): $e');
    }

    // 3. Busca as tarefas compartilhadas com o usuário
    try {
      final resShared = await _client.from('tasks').select().contains('sharedWith', jsonUserId);
      allTasks.addAll(resShared as List<dynamic>);
    } catch (e) {
      debugPrint('Erro ao buscar tarefas (sharedWith): $e');
    }

    // Removendo possíveis tarefas duplicadas (uma tarefa pode ter sido criada
    // e atribuída à mesma pessoa, ou retornada nos múltiplos fluxos)
    final Map<String, dynamic> uniqueTasks = {};
    for (var map in allTasks) {
      uniqueTasks[map['id']] = map;
    }
    
    return uniqueTasks.values.map((map) => Task.fromMap(map)).toList();
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
      debugPrint('Erro ao adicionar tarefa no Supabase: $e');
      throw Exception('Falha ao salvar tarefa no Supabase.');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _client.from('tasks').update(task.toMap()).eq('id', task.id);
    } catch (e) {
      debugPrint('Erro ao atualizar tarefa: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      debugPrint('Erro ao deletar tarefa: $e');
    }
  }
}
