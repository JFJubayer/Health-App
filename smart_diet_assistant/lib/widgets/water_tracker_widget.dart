// pubspec.yaml — add this dependency:
// water_animation: ^1.0.0   (check pub.dev for latest version)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:water_animation/water_animation.dart';
import '../providers/user_provider.dart';
import 'water_goal_dialog.dart';

// ─── Color constants ───────────────────────────────────────────────────────
const _kBlue       = Color(0xFF2563EB);
const _kBlueMid    = Color(0xFF3B82F6);
const _kBlueFaint  = Color(0xFFEFF6FF);
const _kBlueBorder = Color(0xFFBFDBFE);

// Hydration status — color chips change as user drinks
_HydrationStatus _statusFor(double progress) {
  if (progress >= 1.0) return _HydrationStatus.done;
  if (progress >= 0.6) return _HydrationStatus.good;
  if (progress >= 0.3) return _HydrationStatus.fair;
  return _HydrationStatus.low;
}

enum _HydrationStatus { low, fair, good, done }

// ─── Widget ────────────────────────────────────────────────────────────────
class WaterTrackerWidget extends StatelessWidget {
  const WaterTrackerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider  = Provider.of<UserProvider>(context);
    final progress  = (provider.waterIntake / provider.waterGoal).clamp(0.0, 1.0);
    final remaining = (provider.waterGoal - provider.waterIntake).clamp(0, provider.waterGoal);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final status    = _statusFor(progress);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : _kBlueMid.withValues(alpha: 0.10),
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _kBlueMid.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      // ClipRRect so the WaterAnimation fills flush to the card edges
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header + stats (padded section) ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HYDRATION',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          // Settings button
                          GestureDetector(
                            onTap: () => showWaterGoalSheet(context),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 15,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Progress chip
                          _ProgressChip(status: status, progress: progress),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 250.ms),

                  const SizedBox(height: 14),

                  // Stats row: big ml + goal + remaining
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${provider.waterIntake}',
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'ml',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'of ${provider.waterGoal}ml',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${remaining}ml left',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _kBlueMid,
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

                  const SizedBox(height: 12),

                  // Thin progress bar beneath stats
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : _kBlueFaint,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status == _HydrationStatus.done
                              ? const Color(0xFF059669)
                              : _kBlueMid,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 140.ms, duration: 300.ms),
                ],
              ),
            ),

            // ── WaterAnimation — full bleed, no padding ────────────────
            // LayoutBuilder gives us the exact width so WaterAnimation
            // fills flush to both edges of the card.
            LayoutBuilder(
              builder: (context, constraints) {
                return WaterAnimation(
                  width: constraints.maxWidth,
                  height: 130,
                  waterFillFraction: progress,
                  fillTransitionDuration:
                      const Duration(milliseconds: 900),
                  fillTransitionCurve: Curves.easeInOut,

                  // Wave shape parameters
                  amplitude:   13,
                  frequency:   1.0,
                  speed:       2.5,
                  realisticWave: true,

                  // Primary wave — blue gradient (gradientColors enables it implicitly)
                  waterColor: const Color(0xFF60A5FA),
                  gradientColors: const [
                    Color(0xFF60A5FA), // light blue top
                    Color(0xFF1D4ED8), // deep blue bottom
                  ],

                  // Second wave — adds depth and layering
                  enableSecondWave:      true,
                  secondWaveAmplitude:   8,
                  secondWaveFrequency:   1.6,
                  secondWaveSpeed:       1.3,
                  secondWaveColor:
                      const Color(0xFF93C5FD).withValues(alpha: 0.45),

                  // Subtle light-reflection shimmer
                  enableShader: true,

                  // Container background (the "empty" part of the tank)
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A) // dark slate
                        : _kBlueFaint,
                  ),
                );
              },
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            // ── Quick-add buttons ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _AddButton(
                      icon: Icons.water_drop_outlined,
                      amount: 150,
                      label: 'Sip',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.addWater(150);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AddButton(
                      icon: Icons.local_cafe_outlined,
                      amount: 250,
                      label: 'Glass',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.addWater(250);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AddButton(
                      icon: Icons.water_outlined,
                      amount: 500,
                      label: 'Bottle',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.addWater(500);
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 260.ms, duration: 350.ms)
               .slideY(begin: 0.06, curve: Curves.easeOutCubic),
            ),

            // ── Reset row ──────────────────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.resetWater();
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  'Reset today',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 320.ms, duration: 300.ms),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Progress chip ─────────────────────────────────────────────────────────
class _ProgressChip extends StatelessWidget {
  final _HydrationStatus status;
  final double progress;

  const _ProgressChip({required this.status, required this.progress});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    final String label;

    switch (status) {
      case _HydrationStatus.done:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF065F46);
        border = const Color(0xFFA7F3D0);
        label = 'Done!';
      case _HydrationStatus.good:
        bg = _kBlueFaint;
        fg = const Color(0xFF1D4ED8);
        border = _kBlueBorder;
        label = '${(progress * 100).toInt()}%';
      case _HydrationStatus.fair:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        border = const Color(0xFFFDE68A);
        label = '${(progress * 100).toInt()}%';
      case _HydrationStatus.low:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFF991B1B);
        border = const Color(0xFFFECACA);
        label = '${(progress * 100).toInt()}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Add button ────────────────────────────────────────────────────────────
class _AddButton extends StatefulWidget {
  final IconData icon;
  final int amount;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.amount,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 12),
        transform: _pressed
            ? Matrix4.diagonal3Values(0.96, 0.96, 1.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _pressed
              ? _kBlueFaint
              : (widget.isDark
                  ? _kBlueMid.withValues(alpha: 0.10)
                  : _kBlueFaint.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed
                ? _kBlueBorder
                : (widget.isDark
                    ? _kBlueMid.withValues(alpha: 0.18)
                    : _kBlueBorder.withValues(alpha: 0.5)),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _kBlueMid, size: 20),
            const SizedBox(height: 5),
            Text(
              '+${widget.amount}ml',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}