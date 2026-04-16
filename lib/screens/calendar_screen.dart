import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Get tasks for a specific day
  List<Task> _getTasksForDay(DateTime day, TaskProvider provider) {
    return provider.tasks.where((task) {
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Consumer<TaskProvider>(
                builder: (context, provider, child) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TableCalendar<Task>(
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay; 
                        });
                      },
                      eventLoader: (day) => _getTasksForDay(day, provider),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: GoogleFonts.inter(color: AppTheme.textWhite),
                        weekendTextStyle: GoogleFonts.inter(color: AppTheme.textBody),
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.primaryNeon,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.secondaryNeon.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle: GoogleFonts.inter(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w600),
                        formatButtonVisible: false,
                        leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textWhite),
                        rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textWhite),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: GoogleFonts.inter(color: AppTheme.textBody),
                        weekendStyle: GoogleFonts.inter(color: AppTheme.textBody),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              final selectedTasks = _getTasksForDay(_selectedDay!, provider);
              
              if (selectedTasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        "Nenhuma tarefa para este dia.",
                        style: GoogleFonts.inter(color: AppTheme.textBody),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildTaskItem(selectedTasks[index]);
                    },
                    childCount: selectedTasks.length,
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
      decoration: BoxDecoration(
        gradient: AppTheme.topHeaderGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendário',
                style: GoogleFonts.inter(
                  color: AppTheme.textWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateTaskScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.textWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppTheme.secondaryNeon, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskItem(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: task.priority == 'Alta'
                ? AppTheme.primaryNeon.withValues(alpha: 0.5)
                : task.priority == 'Média'
                    ? Colors.orange.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
             GestureDetector(
                onTap: () {
                  Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskStatus(task.id);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isDone
                        ? AppTheme.activeGreen.withValues(alpha: 0.2)
                        : AppTheme.backgroundDark,
                  ),
                  child: Icon(
                    task.isDone ? Icons.check : Icons.circle_outlined,
                    color: task.isDone
                        ? AppTheme.activeGreen
                        : AppTheme.textBody,
                    size: 28,
                  ),
                ),
             ),
             SizedBox(width: 16),
             Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        color: task.isDone
                            ? AppTheme.textBody
                            : AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      task.isDone ? 'Concluída' : 'Pendente',
                      style: GoogleFonts.inter(
                        color: task.isDone
                            ? AppTheme.textBody
                            : AppTheme.activeGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
             )
          ]
        )
      )
    );
  }
}
