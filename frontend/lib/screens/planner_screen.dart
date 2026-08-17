import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../services/planner_service.dart';
import '../utils/translations.dart';

class PlannerScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const PlannerScreen({super.key, this.onNavigate});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  static const Color kGreen = Color(0xFF00FF40);
  static const Color kBg = Color(0xFF0A0C10);
  static const Color kCard = Color(0xFF151922);

  late TabController _tabController;
  final PlannerService _planner = PlannerService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPlanner();
  }

  Future<void> _initPlanner() async {
    await _planner.init();
    _planner.addListener(_onPlannerUpdate);
    if (mounted) setState(() => _isLoading = false);
  }

  void _onPlannerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _planner.removeListener(_onPlannerUpdate);
    _tabController.dispose();
    super.dispose();
  }

  // ── Priority helpers ─────────────────────────────────────────────────────
  Color _priorityColor(String p) {
    switch (p) {
      case 'critical':
        return const Color.fromARGB(255, 253, 0, 0);
      case 'high':
        return const Color.fromARGB(255, 255, 123, 0);
      case 'medium':
        return const Color.fromARGB(255, 255, 251, 0);
      default:
        return const Color.fromARGB(255, 0, 255, 0);
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning_amber;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.low_priority;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'critical':
        return 'CRITICAL';
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'audit':
        return Icons.policy;
      case 'monitoring':
        return Icons.monitor_heart;
      case 'incident':
        return Icons.crisis_alert;
      case 'training':
        return Icons.school;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.task_alt;
    }
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'audit':
        return 'Security Audit';
      case 'monitoring':
        return 'Monitoring';
      case 'incident':
        return 'Incident Response';
      case 'training':
        return 'Training';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'General';
    }
  }

  String _reminderLabel(int minutes) {
    if (minutes <= 0) return 'No reminder';
    if (minutes < 60) return '$minutes min before';
    if (minutes < 1440) return '${minutes ~/ 60}h before';
    if (minutes == 10080) return '1 week before';
    if (minutes == 14400) return '10 days before';
    if (minutes == 20160) return '2 weeks before';
    return '${minutes ~/ 1440} day(s) before';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$m';
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kGreen.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildScoreHeader(),
                _buildTabBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: kGreen),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildActiveTasksList(),
                            _buildHistoryList(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          backgroundColor: kGreen,
          foregroundColor: Colors.black,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!(3); // Go back to Dashboard
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/plannericon.webp',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Icon(
                Icons.smart_toy,
                color: kGreen.withValues(alpha: 0.8),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('planner_title', fallback: 'CYBER PLANNER'),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Header ────────────────────────────────────────────────────────
  Widget _buildScoreHeader() {
    final score = _planner.completionScore;
    final completed = _planner.completedCount;
    final missed = _planner.missedCount;
    final active = _planner.activeTasks.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                // Score circle
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: score >= 80
                              ? kGreen
                              : score >= 50
                              ? const Color.fromARGB(255, 255, 191, 0)
                              : const Color.fromARGB(255, 255, 0, 0),
                        ),
                      ),
                      Text(
                        '${score.round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'planner_completion_rate',
                          fallback: 'Completion Rate',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: kGreen.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.rocket_launch,
                            '$active',
                            'Active',
                            const Color.fromARGB(255, 255, 16, 215),
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.check_circle,
                            '$completed',
                            'Done',
                            const Color.fromARGB(255, 81, 255, 0),
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.cancel,
                            '$missed',
                            'Missed',
                            const Color.fromARGB(255, 255, 0, 0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kGreen.withValues(alpha: 0.3)),
        ),
        labelColor: kGreen,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        tabs: [
          Tab(text: context.tr('planner_active', fallback: 'Active Tasks')),
          Tab(text: context.tr('planner_history', fallback: 'History')),
        ],
      ),
    );
  }

  // ── Active Tasks List ───────────────────────────────────────────────────
  Widget _buildActiveTasksList() {
    final tasks = _planner.activeTasks;
    if (tasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt,
        title: context.tr('planner_no_tasks', fallback: 'No Active Tasks'),
        subtitle: context.tr(
          'planner_no_tasks_desc',
          fallback: 'Tap + to add your first cyber task',
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  // ── History List ────────────────────────────────────────────────────────
  Widget _buildHistoryList() {
    final tasks = _planner.historyTasks;
    if (tasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: context.tr('planner_no_history', fallback: 'No History Yet'),
        subtitle: context.tr(
          'planner_no_history_desc',
          fallback: 'Completed and missed tasks appear here',
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildHistoryCard(tasks[index]),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  // ── Task Card ──────────────────────────────────────────────────────────
  Widget _buildTaskCard(CyberTask task) {
    final pColor = _priorityColor(task.priority);
    final isOverdue = task.dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: kCard.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOverdue
                    ? const Color(0xFFFF1744).withValues(alpha: 0.4)
                    : pColor.withValues(alpha: 0.2),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTaskDetails(task),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Priority indicator
                      Container(
                        width: 4,
                        height: 52,
                        decoration: BoxDecoration(
                          color: pColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _categoryIcon(task.category),
                          size: 20,
                          color: pColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: isOverdue
                                      ? const Color(0xFFFF1744)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDate(task.dueDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isOverdue
                                          ? const Color(0xFFFF1744)
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.reminderMinutesBefore > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      size: 11,
                                      color: Color(0xFFFFC107),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _reminderLabel(
                                        task.reminderMinutesBefore,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFFFFC107),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _priorityLabel(task.priority),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: pColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Complete button
                      GestureDetector(
                        onTap: () => _planner.completeTask(task.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kGreen.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 18,
                            color: kGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── History Card ───────────────────────────────────────────────────────
  Widget _buildHistoryCard(CyberTask task) {
    final isCompleted = task.isCompleted;
    final statusColor = isCompleted
        ? const Color.fromARGB(255, 43, 255, 0)
        : const Color.fromARGB(255, 255, 0, 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: kCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.15)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: statusColor,
              ),
            ),
            title: Text(
              task.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white30,
              ),
            ),
            subtitle: Text(
              isCompleted
                  ? 'Completed ${_formatDate(task.completedAt ?? task.dueDate)}'
                  : 'Missed — was due ${_formatDate(task.dueDate)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: statusColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categoryLabel(task.category),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Task Details Bottom Sheet ───────────────────────────────────────────
  void _showTaskDetails(CyberTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCard.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _priorityColor(
                          task.priority,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _categoryIcon(task.category),
                        size: 28,
                        color: _priorityColor(task.priority),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _priorityColor(
                                    task.priority,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _priorityLabel(task.priority),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _priorityColor(task.priority),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _categoryLabel(task.category),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    task.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _detailRow(Icons.schedule, 'Due', _formatDate(task.dueDate)),
                if (task.reminderMinutesBefore > 0)
                  _detailRow(
                    Icons.notifications_active,
                    'Reminder',
                    _reminderLabel(task.reminderMinutesBefore),
                  ),
                _detailRow(
                  Icons.calendar_today,
                  'Created',
                  _formatDate(task.createdAt),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _planner.deleteTask(task.id);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF1744),
                          side: BorderSide(
                            color: const Color(
                              0xFFFF1744,
                            ).withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _planner.completeTask(task.id);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen.withValues(alpha: 0.15),
                          foregroundColor: kGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: kGreen.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Task Dialog ────────────────────────────────────────────────────
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    String category = 'other';
    DateTime dueDate = DateTime.now().add(const Duration(hours: 1));
    List<int> selectedReminders = [30];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCard.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(
                          'planner_add_task',
                          fallback: 'New Cyber Task',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      _dialogField(
                        titleCtrl,
                        context.tr(
                          'planner_task_title',
                          fallback: 'Task Title',
                        ),
                        Icons.edit,
                      ),
                      const SizedBox(height: 12),
                      // Description
                      _dialogField(
                        descCtrl,
                        context.tr(
                          'planner_task_desc',
                          fallback: 'Description (optional)',
                        ),
                        Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Priority selector
                      Text(
                        'Priority',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['critical', 'high', 'medium', 'low'].map((
                          p,
                        ) {
                          final selected = priority == p;
                          final c = _priorityColor(p);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => priority = p),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? c.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? c.withValues(alpha: 0.4)
                                        : Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _priorityIcon(p),
                                      size: 18,
                                      color: selected ? c : Colors.white30,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _priorityLabel(p),
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: selected ? c : Colors.white30,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Category selector
                      Text(
                        'Category',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              'audit',
                              'monitoring',
                              'incident',
                              'training',
                              'maintenance',
                              'other',
                            ].map((c) {
                              final selected = category == c;
                              return GestureDetector(
                                onTap: () => setDialogState(() => category = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? kGreen.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? kGreen.withValues(alpha: 0.3)
                                          : Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _categoryIcon(c),
                                        size: 14,
                                        color: selected
                                            ? kGreen
                                            : Colors.white30,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _categoryLabel(c),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? kGreen
                                              : Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Due date
                      _dialogPickerRow(
                        icon: Icons.event,
                        label: 'Due: ${_formatDate(dueDate)}',
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: kGreen,
                                  surface: Color(0xFF1A1E28),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null && ctx.mounted) {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(dueDate),
                              builder: (context, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: kGreen,
                                    surface: Color(0xFF1A1E28),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (time != null) {
                              setDialogState(() {
                                dueDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Reminder
                      _dialogPickerRow(
                        icon: Icons.notifications_active,
                        label: selectedReminders.isEmpty
                            ? 'No reminder'
                            : 'Reminder: ${selectedReminders.map(_reminderLabel).join(', ')}',
                        onTap: () {
                          showModalBottomSheet(
                            context: ctx,
                            backgroundColor: const Color(0xFF1A1E28),
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (innerCtx) => StatefulBuilder(
                              builder: (innerCtx, setInnerState) => Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Set Reminders',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Flexible(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              [
                                                    10,
                                                    15,
                                                    30,
                                                    60,
                                                    120,
                                                    1440,
                                                    2880,
                                                    10080,
                                                    14400,
                                                    20160,
                                                  ]
                                                  .map(
                                                    (mins) => CheckboxListTile(
                                                      value: selectedReminders
                                                          .contains(mins),
                                                      activeColor: kGreen,
                                                      checkColor: Colors.black,
                                                      title: Text(
                                                        _reminderLabel(mins),
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                      ),
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      onChanged: (val) {
                                                        setInnerState(() {
                                                          if (val == true) {
                                                            selectedReminders
                                                                .add(mins);
                                                          } else {
                                                            selectedReminders
                                                                .remove(mins);
                                                          }
                                                          selectedReminders
                                                              .sort();
                                                        });
                                                        setDialogState(() {});
                                                      },
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(innerCtx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kGreen,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text(
                                          'Done',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (titleCtrl.text.trim().isEmpty) return;
                            final task = CyberTask(
                              id: const Uuid().v4(),
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              priority: priority,
                              category: category,
                              createdAt: DateTime.now(),
                              dueDate: dueDate,
                              reminderMinutesBefore:
                                  selectedReminders.isNotEmpty
                                  ? selectedReminders.first
                                  : 0,
                              reminders: selectedReminders,
                            );
                            _planner.addTask(task);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.add_task, size: 20),
                          label: Text(
                            context.tr(
                              'planner_save_task',
                              fallback: 'Save Task',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        prefixIcon: Icon(icon, color: kGreen.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kGreen.withValues(alpha: 0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dialogPickerRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kGreen.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
