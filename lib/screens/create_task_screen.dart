import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../services/security_utils.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../services/supabase_auth_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const CreateTaskScreen({super.key, this.taskToEdit});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPriority = 'Média';
  String _selectedCategory = 'Sem Categoria';
  String _selectedStatus = 'Pendente';
  bool _hasAlarm = false;
  String _selectedRecurrence = 'S/ Repetição';
  List<ChecklistItem> _checklist = [];
  final _checklistController = TextEditingController();

  final _memberEmailController = TextEditingController();
  String _selectedMemberRole = 'Executor'; 
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = false;

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _selectedDate = widget.taskToEdit!.dueDate;
      _selectedPriority = widget.taskToEdit!.priority;
      _selectedCategory = widget.taskToEdit!.category;
      _selectedStatus = widget.taskToEdit!.status;
      _hasAlarm = widget.taskToEdit!.hasAlarm;
      _selectedRecurrence = widget.taskToEdit!.recurrence;
      _checklist = List.from(widget.taskToEdit!.checklist);
      _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final authService = SupabaseAuthService();
    List<Map<String, dynamic>> loadedMembers = [];

    for (String id in widget.taskToEdit!.assignedTo) {
      final data = await authService.getUserById(id);
      if (data != null) {
        loadedMembers.add({'id': id, 'email': data['email'], 'role': 'Executor', 'name': data['name']});
      }
    }
    for (String id in widget.taskToEdit!.sharedWith) {
      final data = await authService.getUserById(id);
      if (data != null) {
        loadedMembers.add({'id': id, 'email': data['email'], 'role': 'Observador', 'name': data['name']});
      }
    }

    if (mounted) {
      setState(() {
        _members = loadedMembers;
        _isLoadingMembers = false;
      });
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryNeon,
              onPrimary: AppTheme.textWhite,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) return;
      
      showTimePicker(
        context: context,
        initialTime: _selectedDate != null 
            ? TimeOfDay.fromDateTime(_selectedDate!) 
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryNeon,
                onPrimary: AppTheme.textWhite,
                surface: AppTheme.cardColor,
                onSurface: AppTheme.textWhite,
                onSurfaceVariant: AppTheme.textBody,
              ),
            ),
            child: child!,
          );
        },
      ).then((pickedTime) {
        if (pickedTime == null) return;
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      });
    });
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        String resultStatus = 'created';
        final sanitizedTitle = SecurityUtils.sanitizeInput(_titleController.text);
        final sanitizedDescription = SecurityUtils.sanitizeInput(_descriptionController.text);

        if (widget.taskToEdit == null) {
          // Create new
          final newTask = Task(
            id: _uuid.v4(),
            title: sanitizedTitle,
            description: sanitizedDescription,
            dueDate: _selectedDate!,
            priority: _selectedPriority,
            category: _selectedCategory,
            status: _selectedStatus,
            createdBy: SupabaseConfig.client.auth.currentUser?.id ?? '',
            assignedTo: _members.where((m) => m['role'] == 'Executor').map((m) => m['id'] as String).toList(),
            sharedWith: _members.where((m) => m['role'] == 'Observador').map((m) => m['id'] as String).toList(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            checklist: _checklist,
            hasAlarm: _hasAlarm,
            recurrence: _selectedRecurrence,
            history: [
              TaskHistoryEvent(
                id: _uuid.v4(),
                userId: SupabaseConfig.client.auth.currentUser?.id ?? 'LocalUser',
                action: 'Criou a tarefa',
                timestamp: DateTime.now()
              )
            ]
          );
          await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
          resultStatus = 'created';
          
          try {
            await NotificationService().scheduleTaskNotification(newTask);
          } catch (e) {
            String errorMsg = e.toString().contains('passado') 
                ? 'A data do alarme não pode ser no passado.' 
                : 'Erro ao configurar alarme.';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg)),
              );
            }
          }
        } else {
          // Update existing
          final updatedTask = widget.taskToEdit!.copyWith(
            title: sanitizedTitle,
            description: sanitizedDescription,
            dueDate: _selectedDate,
            priority: _selectedPriority,
            category: _selectedCategory,
            status: _selectedStatus,
            assignedTo: _members.where((m) => m['role'] == 'Executor').map((m) => m['id'] as String).toList(),
            sharedWith: _members.where((m) => m['role'] == 'Observador').map((m) => m['id'] as String).toList(),
            updatedAt: DateTime.now(),
            checklist: _checklist,
            hasAlarm: _hasAlarm,
            recurrence: _selectedRecurrence,
            history: [
              ...widget.taskToEdit!.history,
              TaskHistoryEvent(
                id: _uuid.v4(),
                userId: SupabaseConfig.client.auth.currentUser?.id ?? 'LocalUser',
                action: 'Editou a tarefa',
                timestamp: DateTime.now()
              )
            ]
          );
          await Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
          resultStatus = 'updated';
          
          try {
            await NotificationService().scheduleTaskNotification(updatedTask);
          } catch (e) {
            String errorMsg = e.toString().contains('passado') 
                ? 'A data do alarme não pode ser no passado.' 
                : 'Erro ao configurar alarme.';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg)),
              );
            }
          }
        }

        if (mounted) {
          Navigator.of(context).pop(resultStatus);
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar tarefa: $error')),
          );
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione uma data primeiro.', 
              style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 14)),
          backgroundColor: AppTheme.primaryNeon,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Criar Nova Tarefa' : 'Editar Tarefa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                          fontSize: 18, 
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Título da Tarefa',
                        hintStyle: GoogleFonts.inter(
                            color: AppTheme.textBody,
                            fontSize: 16),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 100,
                      validator: (value) => 
                          (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textWhite),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Descrição da Tarefa...',
                        hintStyle: GoogleFonts.inter(
                            color: AppTheme.textBody,
                            fontSize: 14),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 500,
                      validator: (value) => 
                          (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: _presentDatePicker,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data de Vencimento',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textBody,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDate == null
                                ? 'Toque para Selecionar'
                                : DateFormat('dd MMM yyyy HH:mm', 'pt_BR').format(_selectedDate!),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today, color: AppTheme.secondaryNeon, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Priority Dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prioridade',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedPriority,
                      dropdownColor: AppTheme.cardColor,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.secondaryNeon),
                      items: ['Baixa', 'Média', 'Alta'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag,
                                size: 16,
                                color: value == 'Alta' 
                                  ? AppTheme.primaryNeon 
                                  : value == 'Média' 
                                    ? Colors.orange 
                                    : AppTheme.textBody,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                value,
                                style: GoogleFonts.inter(
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categoria',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: AppTheme.cardColor,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.secondaryNeon),
                      items: ['Sem Categoria', 'Trabalho', 'Estudo', 'Pessoal', 'Outros'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Trabalho' ? Icons.work :
                                value == 'Estudo' ? Icons.book :
                                value == 'Pessoal' ? Icons.person :
                                value == 'Outros' ? Icons.category : Icons.label_off,
                                size: 16,
                                color: AppTheme.textBody,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                value,
                                style: GoogleFonts.inter(
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Repetição Dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repetição',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedRecurrence,
                      dropdownColor: AppTheme.cardColor,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.secondaryNeon),
                      items: ['S/ Repetição', 'Diária', 'Semanal', 'Mensal'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRecurrence = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Membros Section
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
                      'Membros da Tarefa',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _memberEmailController,
                            style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Email do membro...',
                              hintStyle: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 13),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMemberRole,
                                dropdownColor: AppTheme.cardColor,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.secondaryNeon),
                                items: ['Executor', 'Observador'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedMemberRole = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryNeon,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: AppTheme.backgroundDark),
                            onPressed: _isLoadingMembers ? null : () async {
                              final emailAdd = _memberEmailController.text.trim();
                              if (emailAdd.isNotEmpty) {
                                if (_members.any((m) => m['email'] == emailAdd)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Este usuário já foi adicionado.')),
                                  );
                                  return;
                                }
                                setState(() => _isLoadingMembers = true);
                                final authService = SupabaseAuthService();
                                final userProfile = await authService.getUserByEmail(emailAdd);
                                setState(() => _isLoadingMembers = false);
                                
                                if (userProfile != null) {
                                  setState(() {
                                    _members.add({
                                      'id': userProfile['id'],
                                      'email': userProfile['email'],
                                      'name': userProfile['name'],
                                      'role': _selectedMemberRole,
                                    });
                                    _memberEmailController.clear();
                                  });
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Usuário não encontrado.')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingMembers)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
                    else if (_members.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  member['role'] == 'Executor' ? Icons.engineering : Icons.visibility,
                                  color: AppTheme.secondaryNeon, 
                                  size: 16
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['name'] ?? member['email'],
                                        style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        member['role'],
                                        style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _members.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Alarme Switch
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alarm, color: _hasAlarm ? AppTheme.primaryNeon : AppTheme.textBody),
                        const SizedBox(width: 8),
                        Text(
                          'Ativar Alarme',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _hasAlarm,
                      activeColor: AppTheme.primaryNeon,
                      onChanged: (value) {
                        setState(() {
                          _hasAlarm = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Checklist Section
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
                      'Checklist da Tarefa',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _checklistController,
                            style: GoogleFonts.inter(color: AppTheme.textWhite),
                            decoration: InputDecoration(
                              hintText: 'Adicionar sub-tarefa...',
                              hintStyle: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 14),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryNeon,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: AppTheme.backgroundDark),
                            onPressed: () {
                              if (_checklistController.text.trim().isNotEmpty) {
                                setState(() {
                                  _checklist.add(
                                    ChecklistItem(
                                      id: _uuid.v4(),
                                      title: _checklistController.text.trim(),
                                    )
                                  );
                                  _checklistController.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_checklist.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklist.length,
                        itemBuilder: (context, index) {
                          final item = _checklist[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  item.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: item.isDone ? AppTheme.primaryNeon : AppTheme.textBody, 
                                  size: 20
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      color: item.isDone ? AppTheme.textBody : AppTheme.textWhite,
                                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _checklist.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              if (widget.taskToEdit != null && widget.taskToEdit!.history.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    border: Border.all(color: AppTheme.primaryNeon, width: 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppTheme.cardColor,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (ctx) => _buildHistoryModal(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.history, color: AppTheme.primaryNeon),
                    label: Text(
                      'Ver Histórico de Alterações',
                      style: GoogleFonts.inter(color: AppTheme.primaryNeon, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    widget.taskToEdit == null ? 'Criar Tarefa' : 'Salvar Alterações',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryModal() {
    final history = widget.taskToEdit!.history;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histórico de Alterações', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final ev = history[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle, color: AppTheme.secondaryNeon, size: 12),
                  title: Text(ev.action, style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 14)),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(ev.timestamp),
                    style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 12)
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
