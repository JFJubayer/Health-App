import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import 'glass_card.dart';

/// A premium alert banner with two named constructors:
///   SmartAlertBanner.workoutReminder — amber/orange info-style alert
///   SmartAlertBanner.calorieWarning  — red warning-style alert
class SmartAlertBanner extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final bool isWarning;

  const SmartAlertBanner._({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onDismiss,
    this.onTap,
    this.isWarning = false,
  });

  /// Workout reminder alert — shows when user hasn't logged a workout today (after 3 PM).
  factory SmartAlertBanner.workoutReminder({
    Key? key,
    required UserProvider userProvider,
    VoidCallback? onNavigateToWorkouts,
  }) {
    return SmartAlertBanner._(
      key: key,
      icon: '🏋️',
      title: 'You haven\'t worked out today',
      subtitle: 'Even a quick 15-minute session can help. Tap to get started!',
      accentColor: const Color(0xFFF59E0B), // Amber
      onDismiss: () => userProvider.dismissWorkoutAlert(),
      onTap: onNavigateToWorkouts,
      isWarning: false,
    );
  }

  /// High-calorie warning alert — shows when user on weight-loss plan
  /// has exceeded calorie target by >15% today or over consecutive days.
  factory SmartAlertBanner.calorieWarning({
    Key? key,
    required UserProvider userProvider,
  }) {
    final days = userProvider.effectiveOverCalorieDays > 0
        ? userProvider.effectiveOverCalorieDays
        : (userProvider.consecutiveOverCalorieDays > 0
            ? userProvider.consecutiveOverCalorieDays
            : 1);
    final target = userProvider.calorieTarget.toInt();
    final isSevere = days >= 3;

    String title;
    String subtitle;

    if (days == 1) {
      title = 'Calorie overspend alert';
      subtitle =
          'You\'ve exceeded your $target kcal target by over 15%. Consider lighter options to stay on track.';
    } else if (days == 2) {
      title = 'Calorie overspend — 2 days in a row';
      subtitle =
          'You\'ve been over your $target kcal goal for 2 days in a row. Consider lighter meals today.';
    } else {
      title = 'Calorie overspend — $days days in a row';
      subtitle =
          'You\'ve exceeded your $target kcal target for $days consecutive days. This is slowing your weight loss progress.';
    }

    return SmartAlertBanner._(
      key: key,
      icon: isSevere ? '🚨' : '⚠️',
      title: title,
      subtitle: subtitle,
      accentColor: isSevere ? const Color(0xFFEF4444) : const Color(0xFFF97316), // Red / Orange
      onDismiss: () => userProvider.dismissCalorieWarning(),
      isWarning: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: const TextStyle(fontSize: 22),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .then(delay: 500.ms)
                .then(duration: isWarning ? 400.ms : 1200.ms)
                .custom(
                  builder: (context, value, child) {
                    if (isWarning) {
                      // Subtle shake for warnings
                      final offset = (value * 2 - 1) * 3;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    } else {
                      // Gentle pulse for workout reminder
                      final scale = 1.0 + (value * 0.06);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    }
                  },
                ),

            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Go to Workouts',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Dismiss button
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.15, duration: 400.ms, curve: Curves.easeOut);
  }
}
