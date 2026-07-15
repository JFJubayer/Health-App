import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SegmentedCalorieArc extends StatelessWidget {
  final double consumed;
  final double target;

  const SegmentedCalorieArc({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final currentDateStr = DateFormat('d MMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      height: 230,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segmented Arc
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(
                progress: progress,
                isDark: isDark,
              ),
            ),
          ),

          // Central details (Lightning, Date, Consumed, Goal)
          Positioned(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bolt and Date row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFF79E74),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentDateStr,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Calorie value
                Text(
                  '${consumed.toInt()} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                // Goal text
                Text(
                  'Goal ${target.toInt()} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF79E74),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ArcPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius should be sized to fit nicely
    final radius = min(size.width, size.height) / 2 - 16;

    // Segment definition
    const int totalSegments = 11;
    const double startAngleOffsetDeg = 140.0;
    const double segmentSweepDeg = 20.0;
    const double gapSweepDeg = 6.0;

    // Stroke parameters
    final rect = Rect.fromCircle(center: center, radius: radius);
    final filledSegments = (progress * totalSegments).round();

    for (int i = 0; i < totalSegments; i++) {
      // Determine segment color
      final isFilled = i < filledSegments;
      final paintColor = isFilled
          ? const Color(0xFFF79E74)
          : (isDark ? const Color(0xFF333336) : const Color(0xFFE5E0DA));

      final paint = Paint()
        ..color = paintColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      // Calculate start angle and sweep in radians
      // Start angle begins at bottom left (140 degrees)
      double startAngle = (startAngleOffsetDeg + i * (segmentSweepDeg + gapSweepDeg)) * pi / 180;
      double sweepAngle = segmentSweepDeg * pi / 180;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
