import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:water_animation/water_animation.dart';
import '../providers/user_provider.dart';

// ─── Entry point ───────────────────────────────────────────────────────────
// Call this from WaterTrackerWidget's settings button.
// Using a bottom sheet instead of AlertDialog — more modern, more spacious.
Future<void> showWaterGoalSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Drag-to-dismiss enabled by default with this setup
    builder: (_) => const _WaterGoalSheet(),
  );
}

// ─── Sheet widget ──────────────────────────────────────────────────────────
class _WaterGoalSheet extends StatefulWidget {
  const _WaterGoalSheet();

  @override
  State<_WaterGoalSheet> createState() => _WaterGoalSheetState();
}

class _WaterGoalSheetState extends State<_WaterGoalSheet> {
  late double _goalMl;
  static const double _minGoal = 1500;
  static const double _maxGoal = 4000;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<UserProvider>(context, listen: false);
    _goalMl = provider.waterGoal.toDouble().clamp(_minGoal, _maxGoal);
  }

  // Derived from 250ml ≈ 1 glass
  int get _estimatedGlasses => (_goalMl / 250).round();

  // Recommended goal from user weight
  int get _recommendedGoal {
    final provider = Provider.of<UserProvider>(context, listen: false);
    return ((provider.user?.weightKg ?? 70) * 35).toInt();
  }

  String get _goalDescription {
    if (_goalMl < 1800) return 'Light · below most recommendations';
    if (_goalMl < 2200) return 'Moderate · good starting point';
    if (_goalMl < 2800) return 'Recommended · based on your weight';
    if (_goalMl < 3500) return 'Active · great for high activity days';
    return 'High · suitable for intense exercise';
  }

  // Chip accent colors per range
  Color get _rangeColor {
    if (_goalMl < 1800) return const Color(0xFFF59E0B);
    if (_goalMl < 3200) return const Color(0xFF059669);
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fraction for the live WaterAnimation preview (normalized 0–1 over full range)
    final previewFraction = ((_goalMl - _minGoal) / (_maxGoal - _minGoal))
        .clamp(0.1, 1.0); // min 0.1 so there's always some water visible

    return Container(
      // Faux-overlay background (avoids fixed-position issues in sheet)
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle area (tappable to dismiss) ─────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: double.infinity, height: 20),
          ),

          // ── Sheet surface ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              // Extra bottom padding for home-indicator on iOS/Android
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Handle pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                // Title
                Text(
                  'Daily water goal',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommended for you: ${_recommendedGoal}ml based on weight',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Live preview card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mini WaterAnimation — updates live as slider moves
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WaterAnimation(
                          width: 72,
                          height: 72,
                          waterFillFraction: previewFraction,
                          fillTransitionDuration:
                              const Duration(milliseconds: 500),
                          fillTransitionCurve: Curves.easeInOut,
                          amplitude: 10,
                          frequency: 1.2,
                          speed: 2.0,
                          waterColor: const Color(0xFF60A5FA),
                          gradientColors: const [
                            Color(0xFF60A5FA),
                            Color(0xFF1D4ED8),
                          ],
                          enableSecondWave: true,
                          secondWaveAmplitude: 6,
                          secondWaveFrequency: 1.5,
                          secondWaveSpeed: 1.0,
                          secondWaveColor:
                              const Color(0xFF93C5FD).withValues(alpha: 0.5),
                          realisticWave: true,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFEFF6FF),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Goal value + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_goalMl.toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    'ml',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '~$_estimatedGlasses glasses per day',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Range description chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _rangeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _goalDescription,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _rangeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Slider ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_minGoal.toInt()}ml',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_maxGoal.toInt()}ml',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF3B82F6),
                    inactiveTrackColor: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFBFDBFE),
                    thumbColor: const Color(0xFF2563EB),
                    overlayColor:
                        const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    valueIndicatorShape:
                        const PaddleSliderValueIndicatorShape(),
                    valueIndicatorColor: const Color(0xFF2563EB),
                    valueIndicatorTextStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Slider(
                    value: _goalMl,
                    min: _minGoal,
                    max: _maxGoal,
                    divisions: 50, // 50ml steps
                    label: '${_goalMl.toInt()}ml',
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _goalMl = value);
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Recommended indicator dot
                _RecommendedIndicator(
                  recommendedGoal: _recommendedGoal,
                  currentGoal: _goalMl.toInt(),
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ── Actions ────────────────────────────────────────────
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Save
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          final provider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          provider.setWaterGoal(_goalMl.toInt());
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Save goal',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recommended goal indicator ────────────────────────────────────────────
// A small helper row that shows whether the user is at, above, or below the
// weight-based recommended goal.
class _RecommendedIndicator extends StatelessWidget {
  final int recommendedGoal;
  final int currentGoal;
  final bool isDark;

  const _RecommendedIndicator({
    required this.recommendedGoal,
    required this.currentGoal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final diff = currentGoal - recommendedGoal;
    final isAtGoal = diff.abs() <= 100;
    final isBelow = diff < -100;

    final Color color;
    final String text;
    final IconData icon;

    if (isAtGoal) {
      color = const Color(0xFF059669);
      text = 'At your recommended goal';
      icon = Icons.check_circle_outline_rounded;
    } else if (isBelow) {
      color = const Color(0xFFF59E0B);
      text = '${diff.abs()}ml below recommended (${recommendedGoal}ml)';
      icon = Icons.info_outline_rounded;
    } else {
      color = const Color(0xFF3B82F6);
      text = '${diff}ml above recommended (${recommendedGoal}ml)';
      icon = Icons.info_outline_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}