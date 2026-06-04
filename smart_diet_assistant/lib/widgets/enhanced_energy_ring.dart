import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/macro_calculator.dart';

class EnhancedEnergyRing extends StatelessWidget {
  final double consumed;
  final double target;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final int mealsConsumed;

  const EnhancedEnergyRing({
    super.key,
    required this.consumed,
    required this.target,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
    this.mealsConsumed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (consumed / target).clamp(0.0, 1.0);
    final warning = MacroCalculator.getMacroImbalanceWarning(
      proteinConsumed: proteinConsumed,
      proteinTarget: proteinTarget,
      carbsConsumed: carbsConsumed,
      carbsTarget: carbsTarget,
      fatConsumed: fatConsumed,
      fatTarget: fatTarget,
    );
    final projected = MacroCalculator.getProjectedIntake(
      consumed: consumed,
      target: target,
      mealsPerDay: 3,
      mealsConsumed: mealsConsumed.toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 50,
                          startDegreeOffset: 270,
                          sections: [
                            PieChartSectionData(
                              color: Theme.of(context).colorScheme.primary,
                              value: progress * 100,
                              radius: 12,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color.fromARGB(57, 170, 147, 168)
                                  : const Color.fromARGB(255, 0, 0, 0),
                              value: (1 - progress) * 100,
                              radius: 10,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${consumed.toInt()}',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'of ${target.toInt()} kcal',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Daily Progress',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _buildMacroBar(
                      context,
                      'Protein',
                      proteinConsumed,
                      proteinTarget,
                      Colors.orange,
                    ),
                    const SizedBox(height: 6),
                    _buildMacroBar(
                      context,
                      'Carbs',
                      carbsConsumed,
                      carbsTarget,
                      Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    _buildMacroBar(
                      context,
                      'Fats',
                      fatConsumed,
                      fatTarget,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _getWarningColor(warning, context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getWarningColor(warning, context).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getWarningIcon(warning),
                  size: 16,
                  color: _getWarningColor(warning, context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getWarningColor(warning, context),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          if (mealsConsumed > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Projected intake: ${projected.toInt()} kcal',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(duration: 500.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroBar(
    BuildContext context,
    String label,
    double consumed,
    double target,
    Color color,
  ) {
    final progress = (consumed / target).clamp(0.0, 1.5);

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1 ? Colors.red : color,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${consumed.toInt()}g',
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: progress > 1 ? Colors.red : color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getWarningColor(String warning, BuildContext context) {
    if (warning.contains('balanced')) {
      return Colors.green;
    } else if (warning.contains('exceeded')) {
      return Colors.orange;
    }
    return Colors.amber;
  }

  IconData _getWarningIcon(String warning) {
    if (warning.contains('balanced')) {
      return Icons.check_circle_outline;
    } else if (warning.contains('exceeded')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline;
  }
}
