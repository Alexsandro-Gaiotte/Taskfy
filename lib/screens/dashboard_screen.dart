import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final totalTasks = provider.tasks.length;
          final completedTasks = provider.completedTasks.length;
          final pendingTasks = provider.activeTasks.length;

          final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estatísticas',
                        style: GoogleFonts.inter(
                          color: AppTheme.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMainStatsCard(totalTasks, completedTasks, pendingTasks, completionRate),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Concluídas', completedTasks, AppTheme.activeGreen)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Pendentes', pendingTasks, AppTheme.secondaryNeon)),
                        ],
                      ),
                      const SizedBox(height: 120), // Bottom padding to avoid nav bar overlap
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.inter(
              color: AppTheme.textWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seu progresso em tarefas',
            style: GoogleFonts.inter(
              color: AppTheme.textBody,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsCard(int totalTasks, int completedTasks, int pendingTasks, double completionRate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryNeon.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taxa de Conclusão',
                  style: GoogleFonts.inter(
                    color: AppTheme.textBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(completionRate * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    color: AppTheme.textWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total de Tarefas: $totalTasks',
                  style: GoogleFonts.inter(
                    color: AppTheme.textBody,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: AppTheme.backgroundDark,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 8,
                      color: AppTheme.primaryNeon,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppTheme.textBody,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
