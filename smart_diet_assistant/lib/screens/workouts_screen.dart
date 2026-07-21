import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

// ──────────────────────────────────────────────
// Data Models
// ──────────────────────────────────────────────

class WorkoutTemplate {
  final String id;
  final String name;
  final String icon;
  final int caloriesPerMinute; // avg cal/min
  final Color color;
  final String category;
  final String description;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.caloriesPerMinute,
    required this.color,
    required this.category,
    required this.description,
  });
}

class WorkoutPlan {
  final String id;
  final String name;
  final String icon;
  final int dailyBurnTarget;
  final String description;
  final Color accentColor;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.icon,
    required this.dailyBurnTarget,
    required this.description,
    required this.accentColor,
  });
}

// ──────────────────────────────────────────────
// Preset Data
// ──────────────────────────────────────────────

const List<WorkoutTemplate> presetWorkouts = [
  WorkoutTemplate(
    id: 'hiit',
    name: 'HIIT Sprint',
    icon: '🔥',
    caloriesPerMinute: 14,
    color: Color(0xFFFF6B6B),
    category: 'Cardio',
    description: 'High-intensity intervals for maximum calorie burn',
  ),
  WorkoutTemplate(
    id: 'running',
    name: 'Running',
    icon: '🏃',
    caloriesPerMinute: 11,
    color: Color(0xFF4ECDC4),
    category: 'Cardio',
    description: 'Steady-state cardio for endurance',
  ),
  WorkoutTemplate(
    id: 'strength',
    name: 'Strength Training',
    icon: '🏋️',
    caloriesPerMinute: 8,
    color: Color(0xFF6C5CE7),
    category: 'Strength',
    description: 'Build muscle, boost metabolism',
  ),
  WorkoutTemplate(
    id: 'cycling',
    name: 'Cycling',
    icon: '🚴',
    caloriesPerMinute: 10,
    color: Color(0xFFFF9F43),
    category: 'Cardio',
    description: 'Low-impact cardio for fat burning',
  ),
  WorkoutTemplate(
    id: 'yoga',
    name: 'Yoga Flow',
    icon: '🧘',
    caloriesPerMinute: 4,
    color: Color(0xFF00B894),
    category: 'Flexibility',
    description: 'Flexibility, balance, and mindfulness',
  ),
  WorkoutTemplate(
    id: 'walking',
    name: 'Brisk Walk',
    icon: '🚶',
    caloriesPerMinute: 5,
    color: Color(0xFF74B9FF),
    category: 'Cardio',
    description: 'Easy and effective daily movement',
  ),
  WorkoutTemplate(
    id: 'jump_rope',
    name: 'Jump Rope',
    icon: '⚡',
    caloriesPerMinute: 13,
    color: Color(0xFFFD79A8),
    category: 'Cardio',
    description: 'Full-body workout, quick burn',
  ),
  WorkoutTemplate(
    id: 'swimming',
    name: 'Swimming',
    icon: '🏊',
    caloriesPerMinute: 9,
    color: Color(0xFF0984E3),
    category: 'Full Body',
    description: 'Total-body, joint-friendly workout',
  ),
];

const List<WorkoutPlan> _workoutPlans = [
  WorkoutPlan(
    id: 'fat_burn',
    name: 'Fat Burn',
    icon: '🔥',
    dailyBurnTarget: 400,
    description: 'Aggressive calorie deficit for weight loss',
    accentColor: Color(0xFFFF6B6B),
  ),
  WorkoutPlan(
    id: 'maintain',
    name: 'Stay Active',
    icon: '💪',
    dailyBurnTarget: 250,
    description: 'Maintain fitness and energy',
    accentColor: Color(0xFF4ECDC4),
  ),
  WorkoutPlan(
    id: 'muscle_build',
    name: 'Muscle Build',
    icon: '🏆',
    dailyBurnTarget: 350,
    description: 'Strength-focused with calorie burn',
    accentColor: Color(0xFF6C5CE7),
  ),
  WorkoutPlan(
    id: 'light',
    name: 'Light & Easy',
    icon: '🌿',
    dailyBurnTarget: 150,
    description: 'Gentle movement for beginners',
    accentColor: Color(0xFF00B894),
  ),
];

// ──────────────────────────────────────────────
// Main Screen
// ──────────────────────────────────────────────

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final burned = provider.burnedCalories;
    final target = provider.workoutDailyTarget;
    final progress = target > 0 ? (burned / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Workouts',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () {
              provider.resetBurnedCalories();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Today's workout data reset", style: GoogleFonts.outfit()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Burn progress header
          _buildBurnProgressHeader(context, burned, target, progress, isDark)
              .animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

          const SizedBox(height: 8),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEBE5DF),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF3E3F43) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFFF79E74),
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Workouts'),
                Tab(text: 'Plans'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutsTab(context, provider, isDark),
                _buildPlansTab(context, provider, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Burn Progress Header
  // ──────────────────────────────────────────────

  Widget _buildBurnProgressHeader(BuildContext context, int burned, int target, double progress, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1E1E1E)]
              : [const Color(0xFFFFF8F5), const Color(0xFFFFF0E8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF79E74).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF79E74).withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: isDark ? const Color(0xFF3E3F43) : const Color(0xFFE5E0DA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? const Color(0xFF00B894) : const Color(0xFFF79E74),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$burned kcal burned',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily goal: $target kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF79E74),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (burned < target)
                      Text(
                        '${target - burned} kcal remaining',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        '🎉 Goal reached!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00B894),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildTodayLogSummary(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final logs = provider.workoutLogs;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(log['icon'] ?? '🏋️', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${log['calories']} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Workouts Tab
  // ──────────────────────────────────────────────

  Widget _buildWorkoutsTab(BuildContext context, UserProvider provider, bool isDark) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Quick Log
        _buildQuickLogCard(context, provider, isDark)
            .animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

        const SizedBox(height: 20),

        // Section title
        Text(
          'Choose a Workout',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        // Workout cards
        ...presetWorkouts.asMap().entries.map((entry) {
          final index = entry.key;
          final workout = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildWorkoutCard(context, provider, workout, isDark)
                .animate()
                .fadeIn(delay: (250 + index * 60).ms)
                .slideX(begin: 0.05),
          );
        }),
      ],
    );
  }

  Widget _buildQuickLogCard(BuildContext context, UserProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController calCtrl = TextEditingController();
    final TextEditingController durCtrl = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E74).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✏️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Log',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Activity name',
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF79E74)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: calCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'kcal',
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF79E74)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: durCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'min',
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF79E74)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? 'Custom Workout' : nameCtrl.text.trim();
                final cal = int.tryParse(calCtrl.text.trim()) ?? 0;
                final dur = int.tryParse(durCtrl.text.trim()) ?? 0;
                if (cal > 0) {
                  provider.logWorkout(
                    name: name,
                    durationMinutes: dur,
                    caloriesBurned: cal,
                    icon: '✏️',
                  );
                  nameCtrl.clear();
                  calCtrl.clear();
                  durCtrl.clear();
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged $cal kcal for "$name"', style: GoogleFonts.outfit()),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF79E74),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Log Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, UserProvider provider, WorkoutTemplate workout, bool isDark) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showWorkoutBottomSheet(context, provider, workout),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: workout.color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: workout.color.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: workout.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(workout.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    workout.description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: workout.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '~${workout.caloriesPerMinute} kcal/min',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: workout.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workout.category,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Workout Bottom Sheet with Timer
  // ──────────────────────────────────────────────

  void _showWorkoutBottomSheet(BuildContext context, UserProvider provider, WorkoutTemplate workout) {
    showWorkoutBottomSheet(context, provider, workout);
  }

  // ──────────────────────────────────────────────
  // Plans Tab
  // ──────────────────────────────────────────────

  Widget _buildPlansTab(BuildContext context, UserProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final currentTarget = provider.workoutDailyTarget;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Choose a Workout Plan',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'This sets your daily calorie burn target',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 130.ms),

        const SizedBox(height: 16),

        ..._workoutPlans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          final isSelected = currentTarget == plan.dailyBurnTarget;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () {
                provider.setWorkoutDailyTarget(plan.dailyBurnTarget);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${plan.name} plan activated — ${plan.dailyBurnTarget} kcal/day target',
                      style: GoogleFonts.outfit(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? plan.accentColor : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: plan.accentColor.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: plan.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(plan.icon, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.description,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: plan.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${plan.dailyBurnTarget} kcal / day',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: plan.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: plan.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (150 + index * 80).ms).slideY(begin: 0.05),
          );
        }),

        const SizedBox(height: 16),

        // Custom target
        _buildCustomTargetCard(context, provider, isDark)
            .animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
      ],
    );
  }

  Widget _buildCustomTargetCard(BuildContext context, UserProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final TextEditingController ctrl = TextEditingController(
      text: provider.workoutDailyTarget.toString(),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Daily Target',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'kcal',
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF79E74)),
                    ),
                    suffixText: 'kcal',
                    suffixStyle: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(ctrl.text.trim());
                  if (val != null && val > 0) {
                    provider.setWorkoutDailyTarget(val);
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Daily target set to $val kcal', style: GoogleFonts.outfit()),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF79E74),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(70, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Set', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Workout Session Bottom Sheet (with Timer)
// ──────────────────────────────────────────────

class _WorkoutSessionSheet extends StatefulWidget {
  final WorkoutTemplate workout;
  final void Function(int durationMinutes, int caloriesBurned) onComplete;

  const _WorkoutSessionSheet({
    required this.workout,
    required this.onComplete,
  });

  @override
  State<_WorkoutSessionSheet> createState() => _WorkoutSessionSheetState();
}

class _WorkoutSessionSheetState extends State<_WorkoutSessionSheet> {
  int _selectedDuration = 20; // minutes

  void _startTimer() {
    final provider = context.read<UserProvider>();
    provider.startWorkout(
      widget.workout.name,
      widget.workout.icon,
      widget.workout.caloriesPerMinute.toDouble(),
      _selectedDuration,
    );
  }

  void _stopTimer() {
    final provider = context.read<UserProvider>();
    provider.stopWorkoutEarly();
  }

  void _completeWorkout() {
    final provider = context.read<UserProvider>();
    final isCurrentActive = provider.activeWorkoutName == widget.workout.name;
    final elapsedSeconds = isCurrentActive ? provider.activeWorkoutElapsedSeconds : 0;
    final currentCalories = (widget.workout.caloriesPerMinute * (elapsedSeconds / 60)).toInt();
    
    provider.completeWorkout();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.workout.name} complete! Burned $currentCalories kcal',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final provider = context.watch<UserProvider>();
    final isCurrentActive = provider.activeWorkoutName == widget.workout.name;

    final isTimerRunning = isCurrentActive && provider.isActiveWorkoutRunning;
    final isTimerComplete = isCurrentActive && provider.isActiveWorkoutComplete;
    final elapsedSeconds = isCurrentActive ? provider.activeWorkoutElapsedSeconds : 0;
    final duration = isCurrentActive ? (provider.activeWorkoutDurationMinutes ?? _selectedDuration) : _selectedDuration;

    final totalSeconds = duration * 60;
    final timerProgress = totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final estimatedCalories = (widget.workout.caloriesPerMinute * duration).toInt();
    final currentCalories = (widget.workout.caloriesPerMinute * (elapsedSeconds / 60)).toInt();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Workout info
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.workout.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(widget.workout.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.workout.description,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Duration selector or timer
          if (!isTimerRunning && !isTimerComplete) ...[
            Text(
              'Select Duration',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [10, 15, 20, 30, 45, 60].map((min) {
                final isSelected = _selectedDuration == min;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = min),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.workout.color
                          : (isDark ? const Color(0xFF3E3F43) : const Color(0xFFEBE5DF)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$min min',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Estimated burn
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.workout.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated burn: ~$estimatedCalories kcal',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.workout.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text('Start Workout', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.workout.color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ),
          ],

          // Timer running
          if (isTimerRunning) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: timerProgress,
                      strokeWidth: 10,
                      backgroundColor: isDark ? const Color(0xFF3E3F43) : const Color(0xFFE5E0DA),
                      valueColor: AlwaysStoppedAnimation(widget.workout.color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(elapsedSeconds),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentCalories kcal',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.workout.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _stopTimer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.workout.color,
                      side: BorderSide(color: widget.workout.color),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('End Early', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],

          // Timer complete
          if (isTimerComplete) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'Workout Complete!',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00B894),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(elapsedSeconds)} · $currentCalories kcal burned',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text('Save & Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Top-Level Helpers for Workout Bottom Sheets
// ──────────────────────────────────────────────

void showWorkoutBottomSheet(BuildContext context, UserProvider provider, WorkoutTemplate workout) {
  if (provider.activeWorkoutName != null && provider.activeWorkoutName != workout.name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A workout "${provider.activeWorkoutName}" is already active. Please complete or cancel it first.',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WorkoutSessionSheet(
      workout: workout,
      onComplete: (durationMinutes, caloriesBurned) {},
    ),
  );
}

void showActiveWorkoutBottomSheet(BuildContext context, UserProvider provider) {
  final activeName = provider.activeWorkoutName;
  if (activeName == null) return;
  final workout = presetWorkouts.firstWhere(
    (w) => w.name == activeName,
    orElse: () => presetWorkouts.first,
  );
  showWorkoutBottomSheet(context, provider, workout);
}
