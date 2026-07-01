import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/greeting_helper.dart';

// ─── Data class for time-of-day theming ────────────────────────────────────
class _TimeTheme {
  final List<Color> gradient;
  final Color accent;      // used on streak badge + motivational bar
  final Color shadow;
  final IconData timeIcon;

  const _TimeTheme({
    required this.gradient,
    required this.accent,
    required this.shadow,
    required this.timeIcon,
  });
}

// ─── Main Widget ───────────────────────────────────────────────────────────
class GreetingHeader extends StatelessWidget {
  final String userName;
  final int streakCount;
  final VoidCallback? onStreakTap;

  const GreetingHeader({
    super.key,
    required this.userName,
    required this.streakCount,
    this.onStreakTap,
  });

  // Four time-of-day themes — each has a distinct color personality
  static _TimeTheme _themeFor(int hour) {
    if (hour >= 5 && hour < 12) {
      // Morning — warm emerald, amber accent
      return const _TimeTheme(
        gradient: [Color(0xFF059669), Color(0xFF0D9488)],
        accent:   Color(0xFFFBBF24),
        shadow:   Color(0x55059669),
        timeIcon: Icons.wb_sunny_outlined,
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon — bright teal
      return const _TimeTheme(
        gradient: [Color(0xFF0D9488), Color(0xFF0891B2)],
        accent:   Color(0xFF34D399),
        shadow:   Color(0x550D9488),
        timeIcon: Icons.light_mode_outlined,
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening — deep forest, warm amber
      return const _TimeTheme(
        gradient: [Color(0xFF065F46), Color(0xFF059669)],
        accent:   Color(0xFFFB923C),
        shadow:   Color(0x55065F46),
        timeIcon: Icons.wb_twilight_outlined,
      );
    } else {
      // Night — deep slate-teal
      return const _TimeTheme(
        gradient: [Color(0xFF1E3A5F), Color(0xFF0D4D6E)],
        accent:   Color(0xFF93C5FD),
        shadow:   Color(0x551E3A5F),
        timeIcon: Icons.nights_stay_outlined,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now         = DateTime.now();
    final theme       = _themeFor(now.hour);
    final greeting    = GreetingHelper.getTimeBasedGreeting(now);
    final motivational = GreetingHelper.getMotivationalMessage(streakCount);
    final formattedDate = GreetingHelper.getFormattedDate(now);

    return Container(
      // Margin so the card floats inside the screen — not edge-to-edge
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        // Colored shadow uses the theme's shadow value — feels intentional
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient background shapes — depth without noise
            _DecorativeCircle(size: 110, top: -28, right: -16, opacity: 0.07),
            _DecorativeCircle(size: 80,  bottom: -36, right: 50, opacity: 0.05),
            // Accent-tinted small circle — ties to the theme accent
            _DecorativeCircle(
              size: 36, top: 22, right: 84,
              opacity: 0.22, color: theme.accent,
            ),

            // ── Main content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Row 1: date pill  ·  streak badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DatePill(
                        icon: theme.timeIcon,
                        accentColor: theme.accent,
                        label: formattedDate,
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 280.ms),

                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onStreakTap?.call();
                        },
                        child: _StreakBadge(
                          count: streakCount,
                          accent: theme.accent,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 280.ms)
                          .slideX(
                            begin: 0.12,
                            duration: 320.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Row 2: greeting label (small, muted)
                  Text(
                    greeting,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.68),
                      letterSpacing: 0.2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 300.ms),

                  const SizedBox(height: 2),

                  // Row 3: user name — large and owning the space
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 350.ms)
                      .slideY(
                        begin: 0.08,
                        duration: 380.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 16),

                  // Hairline divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  )
                      .animate()
                      .fadeIn(delay: 260.ms, duration: 300.ms),

                  const SizedBox(height: 14),

                  // Row 4: motivational strip — accent bar + text
                  _MotivationalStrip(
                    message: motivational,
                    accentColor: theme.accent,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 380.ms)
                      .slideY(
                        begin: 0.06,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Pill ─────────────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;

  const _DatePill({
    required this.icon,
    required this.accentColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Badge ──────────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int count;
  final Color accent;

  const _StreakBadge({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.48),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                count == 1 ? 'day' : 'days',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Motivational Strip ────────────────────────────────────────────────────
// Replaces the heavy frosted-box from the original.
// An accent bar on the left anchors the text — feels editorial and clean.
class _MotivationalStrip extends StatelessWidget {
  final String message;
  final Color accentColor;

  const _MotivationalStrip({
    required this.message,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 38,
          margin: const EdgeInsets.only(right: 11, top: 1),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.48,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Decorative Circle ─────────────────────────────────────────────────────
// Positioned ambient circles that add depth to the card background.
// All white by default (color param overrides for accent-tinted dot).
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double? top;
  final double? bottom;
  final double? right;
  final double opacity;
  final Color color;

  const _DecorativeCircle({
    required this.size,
    this.top,
    this.bottom,
    this.right,
    required this.opacity,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}