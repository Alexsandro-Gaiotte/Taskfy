import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  // Filter states
  String _activeDateFilter = 'Todas'; 
  String _activeStatusFilter = 'Todas'; 
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: AppTheme.textWhite)),
        backgroundColor: AppTheme.primaryNeon,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      )
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
    if (result == 'created' && mounted) {
      _showSuccessMessage('Tarefa criada com sucesso!');
    }
  }

  void _navigateToDetails(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    
    if (mounted) {
      if (result == 'deleted') {
        _showSuccessMessage('Tarefa excluída com sucesso!');
      } else if (result == 'updated') {
        _showSuccessMessage('Tarefa atualizada com sucesso!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterTabs()),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isLoading) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
                );
              }

              List<Task> filteredTasks = taskProvider.tasks;
              
              if (_activeStatusFilter == 'Pendente') {
                 filteredTasks = filteredTasks.where((t) => t.status == 'Pendente').toList();
              } else if (_activeStatusFilter == 'Em Andamento') {
                 filteredTasks = filteredTasks.where((t) => t.status == 'Em andamento').toList();
              } else if (_activeStatusFilter == 'Concluída') {
                 filteredTasks = filteredTasks.where((t) => t.status == 'Concluída').toList();
              }

              if (_activeDateFilter == 'Diária') {
                 final now = DateTime.now();
                 filteredTasks = filteredTasks.where((t) => 
                   t.dueDate.year == now.year && t.dueDate.month == now.month && t.dueDate.day == now.day
                 ).toList();
              } else if (_activeDateFilter == 'Semanal') {
                 final now = DateTime.now();
                 final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                 final endOfWeek = startOfWeek.add(const Duration(days: 6));
                 filteredTasks = filteredTasks.where((t) => 
                   t.dueDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                   t.dueDate.isBefore(endOfWeek.add(const Duration(days: 1)))
                 ).toList();
              } else if (_activeDateFilter == 'Mensal') {
                 final now = DateTime.now();
                 filteredTasks = filteredTasks.where((t) => 
                   t.dueDate.year == now.year && t.dueDate.month == now.month
                 ).toList();
              }

              if (_searchQuery.isNotEmpty) {
                 final query = _searchQuery.toLowerCase();
                 filteredTasks = filteredTasks.where((t) => 
                   t.title.toLowerCase().contains(query) || 
                   t.description.toLowerCase().contains(query)
                 ).toList();
              }

              if (filteredTasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        "Nenhuma tarefa encontrada.\nToque em + para criar uma.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 16),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskItem(filteredTasks[index], index, null),
                    childCount: filteredTasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.topHeaderGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu, color: AppTheme.textWhite, size: 28),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.textWhite.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, color: AppTheme.textWhite, size: 24),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _navigateToCreate,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppTheme.textWhite, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: AppTheme.secondaryNeon, size: 24),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Visão Geral', style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.link, color: AppTheme.textWhite.withValues(alpha: 0.7), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TAREFAS ATIVAS',
            style: GoogleFonts.inter(color: AppTheme.textWhite.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Consumer<TaskProvider>(
            builder: (context, provider, child) => Text(
              '${provider.activeTasks.length}',
              style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 64, fontWeight: FontWeight.w300, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToCreate,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(color: AppTheme.textWhite, borderRadius: BorderRadius.circular(28)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_task, color: AppTheme.backgroundDark),
                        const SizedBox(width: 8),
                        Text('Nova Tarefa', style: GoogleFonts.inter(color: AppTheme.backgroundDark, fontSize: 16, fontWeight: FontWeight.w600))
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Provider.of<TaskProvider>(context, listen: false).clearCompleted();
                    _showSuccessMessage('Tarefas concluídas removidas!');
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(color: AppTheme.textWhite.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(28)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.done_all, color: AppTheme.textWhite),
                        const SizedBox(width: 8),
                        Text('Limpar Feitas', style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w600))
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: GoogleFonts.inter(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'Pesquisar tarefas...',
            hintStyle: GoogleFonts.inter(color: AppTheme.textBody),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textBody),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: _searchQuery.isNotEmpty ? IconButton(
              icon: const Icon(Icons.clear, color: AppTheme.textBody),
              onPressed: () {
                _searchController.clear();
                setState(() { _searchQuery = ''; });
              },
            ) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildSmallPill('Todas'),
              const SizedBox(width: 8),
              _buildSmallPill('Diária'),
              const SizedBox(width: 8),
              _buildSmallPill('Semanal'),
              const SizedBox(width: 8),
              _buildSmallPill('Mensal'),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('Todas'),
                const SizedBox(width: 8),
                _buildStatusChip('Pendente'),
                const SizedBox(width: 8),
                _buildStatusChip('Em Andamento'),
                const SizedBox(width: 8),
                _buildStatusChip('Concluída'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmallPill(String text) {
    bool isActive = _activeDateFilter == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeDateFilter = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryNeon.withValues(alpha: 0.2) : AppTheme.cardColor,
            border: Border.all(color: isActive ? AppTheme.primaryNeon : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(text, style: GoogleFonts.inter(color: isActive ? AppTheme.primaryNeon : AppTheme.textBody, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text) {
    bool isActive = _activeStatusFilter == text;
    return GestureDetector(
      onTap: () => setState(() => _activeStatusFilter = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.buttonGradient : null,
          color: isActive ? null : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: AppTheme.textBody.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          text, 
          style: GoogleFonts.inter(
            color: isActive ? AppTheme.textWhite : AppTheme.textBody, 
            fontSize: 14, 
            fontWeight: FontWeight.w600
          )
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task, int index, Animation<double>? animation) {
    return GestureDetector(
      onTap: () => _navigateToDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: task.priority == 'Alta' ? AppTheme.primaryNeon.withValues(alpha: 0.5) : task.priority == 'Média' ? Colors.orange.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await Provider.of<TaskProvider>(context, listen: false).toggleTaskStatus(task.id);
                if (mounted) {
                  _showSuccessMessage(task.isDone ? 'Tarefa marcada como pendente' : 'Tarefa marcada como concluída');
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: task.isDone ? AppTheme.activeGreen.withValues(alpha: 0.2) : AppTheme.backgroundDark),
                child: Icon(task.isDone ? Icons.check : Icons.circle_outlined, color: task.isDone ? AppTheme.activeGreen : AppTheme.textBody, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: GoogleFonts.inter(color: task.isDone ? AppTheme.textBody : AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w600, decoration: task.isDone ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Text(task.status, style: GoogleFonts.inter(color: task.isDone ? AppTheme.textBody : (task.status == 'Em andamento' ? Colors.orange : AppTheme.activeGreen), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('dd MMM', 'pt_BR').format(task.dueDate), style: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      task.category == 'Trabalho' ? Icons.work :
                      task.category == 'Estudo' ? Icons.book :
                      task.category == 'Pessoal' ? Icons.person : Icons.category,
                      size: 14,
                      color: AppTheme.textBody,
                    ),
                    const SizedBox(width: 4),
                    Text(task.category, style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 14, color: task.priority == 'Alta' ? AppTheme.primaryNeon : task.priority == 'Média' ? Colors.orange : AppTheme.textBody),
                    const SizedBox(width: 4),
                    Text(task.priority, style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
