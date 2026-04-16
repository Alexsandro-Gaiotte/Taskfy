class ChecklistItem {
  final String id;
  final String title;
  final bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  ChecklistItem copyWith({
    String? title,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] ?? false,
    );
  }
}

class TaskHistoryEvent {
  final String id;
  final String userId;
  final String action; // Ex: 'Criou a tarefa', 'Alterou o status para Concluída'
  final DateTime timestamp;

  TaskHistoryEvent({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TaskHistoryEvent.fromMap(Map<String, dynamic> map) {
    return TaskHistoryEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // 'Baixa', 'Média', 'Alta'
  final String status; // 'Pendente', 'Em andamento', 'Concluída'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;
  final List<ChecklistItem> checklist;
  final bool hasAlarm;
  final String recurrence;
  final String createdBy; // userId of the creator
  final List<String> assignedTo; // userIds
  final List<String> sharedWith; // userIds
  final List<TaskHistoryEvent> history;

  bool get isDone => status == 'Concluída';

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.priority = 'Média',
    this.status = 'Pendente',
    required this.createdAt,
    required this.updatedAt,
    this.category = 'Sem Categoria',
    this.checklist = const [],
    this.hasAlarm = false,
    this.recurrence = 'S/ Repetição',
    this.createdBy = '',
    this.assignedTo = const [],
    this.sharedWith = const [],
    this.history = const [],
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    bool? isDone, // For backward compatibility
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    List<ChecklistItem>? checklist,
    bool? hasAlarm,
    String? recurrence,
    String? createdBy,
    List<String>? assignedTo,
    List<String>? sharedWith,
    List<TaskHistoryEvent>? history,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? (isDone != null ? (isDone ? 'Concluída' : 'Pendente') : this.status),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      checklist: checklist ?? this.checklist,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      recurrence: recurrence ?? this.recurrence,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      sharedWith: sharedWith ?? this.sharedWith,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'checklist': checklist.map((x) => x.toMap()).toList(),
      'hasAlarm': hasAlarm,
      'recurrence': recurrence,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'sharedWith': sharedWith,
      'history': history.map((x) => x.toMap()).toList(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      priority: map['priority'] ?? 'Média',
      status: map['status'] ?? (map['isDone'] == true ? 'Concluída' : 'Pendente'), // Backward compatibility
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      category: map['category'] ?? 'Sem Categoria',
      checklist: map['checklist'] != null ? List<ChecklistItem>.from(map['checklist']?.map((x) => ChecklistItem.fromMap(x))) : [],
      hasAlarm: map['hasAlarm'] ?? false,
      recurrence: map['recurrence'] ?? 'S/ Repetição',
      createdBy: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'] != null ? List<String>.from(map['assignedTo']) : [],
      sharedWith: map['sharedWith'] != null ? List<String>.from(map['sharedWith']) : [],
      history: map['history'] != null ? List<TaskHistoryEvent>.from(map['history']?.map((x) => TaskHistoryEvent.fromMap(x))) : [],
    );
  }
}
