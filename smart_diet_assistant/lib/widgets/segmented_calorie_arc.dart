import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class SegmentedCalorieArc extends StatelessWidget {
  final double consumed;
  final double target;
  final double burned;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;

  const SegmentedCalorieArc({
    super.key,
    required this.consumed,
    required this.target,
    required this.burned,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final netCalories = consumed - burned;
    final leftCalories = (target - consumed + burned).toInt().clamp(0, 9999);
    final budgetLimit = target + burned;
    final progress =
        budgetLimit > 0 ? (consumed / budgetLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32), // Classy quarter round corners
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Calorie Target Title & Net Calorie Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${target.toInt()} kcal',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              // Net Calorie Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (netCalories >= 0
                          ? const Color(0xFF4ECDC4)
                          : const Color(0xFFFF6B6B))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (netCalories >= 0
                            ? const Color(0xFF4ECDC4)
                            : const Color(0xFFFF6B6B))
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Net: ${netCalories >= 0 ? "+" : ""}${netCalories.toInt()} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: netCalories >= 0
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Required Calories',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Middle: Eaten Column, Ring Gauge, Burned Column
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Eaten (Intake)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Eaten',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${consumed.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Center: Ring
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CalorieRingPainter(
                            progress: progress,
                            isDark: isDark,
                            progressColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$leftCalories',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'kcal left',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Burned
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: Color(0xFFFF6B6B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Burned',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${burned.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom: Macros Cards
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  context,
                  'Carbs',
                  carbsConsumed,
                  carbsTarget,
                  const Color(0xFF4ECDC4), // Fresh Teal
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroCard(
                  context,
                  'Proteins',
                  proteinConsumed,
                  proteinTarget,
                  const Color(0xFFF79E74), // Warm Peach
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroCard(
                  context,
                  'Fat',
                  fatConsumed,
                  fatTarget,
                  const Color(0xFFFF6B6B), // Soft Coral/Red
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    String label,
    double consumed,
    double target,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${consumed.toStringAsFixed(1)}/${target.toInt()}g',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                consumed > target ? Colors.redAccent : color,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color progressColor;

  _CalorieRingPainter({
    required this.progress,
    required this.isDark,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 10.0;

    // 1. Draw background track
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -pi / 2; // 12 o'clock position (270 degrees)
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // 3. Draw end knob (dot) at the tip of the progress
      final endAngle = startAngle + sweepAngle;
      final knobCenter = Offset(
        center.dx + radius * cos(endAngle),
        center.dy + radius * sin(endAngle),
      );

      // White inner dot with a subtle drop shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(knobCenter, strokeWidth / 2 + 1, shadowPaint);

      final knobPaintInner = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(knobCenter, strokeWidth / 2 - 1.5, knobPaintInner);
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.progressColor != progressColor;
  }
}
