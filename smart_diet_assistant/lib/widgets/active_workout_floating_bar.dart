import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../screens/workouts_screen.dart';
import 'glass_card.dart';

class ActiveWorkoutFloatingBar extends StatelessWidget {
  const ActiveWorkoutFloatingBar({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final activeName = provider.activeWorkoutName;

    if (activeName == null) {
      return const SizedBox.shrink();
    }

    final workout = presetWorkouts.firstWhere(
      (w) => w.name == activeName,
      orElse: () => presetWorkouts.first,
    );

    final totalSeconds = (provider.activeWorkoutDurationMinutes ?? 0) * 60;
    final elapsedSeconds = provider.activeWorkoutElapsedSeconds;
    final remainingSeconds = (totalSeconds - elapsedSeconds).clamp(0, totalSeconds);
    final progress = totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final isComplete = provider.isActiveWorkoutComplete;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => showActiveWorkoutBottomSheet(context, provider),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: workout.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(workout.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Title, progress & timer
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      workout.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isComplete ? 'Complete! 🎉' : _formatDuration(remainingSeconds),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isComplete ? const Color(0xFF00B894) : workout.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? const Color(0xFF3E3F43) : const Color(0xFFE5E0DA),
                    valueColor: AlwaysStoppedAnimation(isComplete ? const Color(0xFF00B894) : workout.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action button
          GestureDetector(
            onTap: () {
              if (isComplete) {
                // Complete/Save workout
                provider.completeWorkout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${workout.name} saved successfully!',
                      style: GoogleFonts.outfit(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                // End early
                provider.stopWorkoutEarly();
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFF00B894) : workout.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isComplete ? Icons.check_rounded : Icons.stop_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
