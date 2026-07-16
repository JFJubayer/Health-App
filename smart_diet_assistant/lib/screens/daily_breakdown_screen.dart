import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

class DailyBreakdownScreen extends StatelessWidget {
  const DailyBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final user = provider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targetCalories = provider.calorieTarget.toInt();
    final consumedCalories = provider.totalConsumedCalories;
    final progress = targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    final proteinConsumed = provider.totalConsumedProtein;
    final carbsConsumed = provider.totalConsumedCarbs;
    final fatConsumed = provider.totalConsumedFat;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3EEFF), // Soft lilac top glow
              Color(0xFFF9F7FC), // White-lilac base
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 20),
                    _buildCalorieRingSection(context, consumedCalories, targetCalories, progress),
                    const SizedBox(height: 32),
                    _buildMacrosOverview(context, proteinConsumed, carbsConsumed, fatConsumed),
                    const SizedBox(height: 24),
                    _buildBurnedCaloriesCard(context, provider),
                    const SizedBox(height: 24),
                    _buildWaterCard(context, provider),
                    const SizedBox(height: 20),
                    _buildHealthScoreCard(context, provider),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Daily Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.black87),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRingSection(BuildContext context, int consumed, int target, double progress) {
    return Center(
      child: Container(
        width: 230,
        height: 230,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.03),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: CalorieGaugePainter(
                  progress: progress,
                  strokeWidth: 26,
                  baseColor: const Color(0xFFE5E7EB), // Light gray track
                  progressColor: const Color(0xFF333333), // Charcoal black progress path
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$consumed/$target',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Calories',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMacrosOverview(BuildContext context, double protein, double carbs, double fat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroTag(context, '${protein.toStringAsFixed(0)} g', 'Protein', const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
        _buildMacroTag(context, '${carbs.toStringAsFixed(0)} g', 'Carbs', const Color(0xFFF3E5F5), const Color(0xFF9E7BFF)),
        _buildMacroTag(context, '${fat.toStringAsFixed(0)} g', 'Fats', const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMacroTag(BuildContext context, String value, String label, Color bgColor, Color textColor) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.26,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(BuildContext context, UserProvider provider) {
    final double waterGoal = provider.waterGoal.toDouble();
    final double waterConsumed = provider.waterIntake.toDouble();
    final double waterProgress = waterGoal > 0 ? (waterConsumed / waterGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${waterConsumed.toInt()}/${waterGoal.toInt()} ml',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Wave animations
          GestureDetector(
            onTap: () {
              provider.addWater(250);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0D4FF), width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: WaterWaveClipper(waterProgress),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF9E7BFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.water_drop_rounded,
                    color: waterProgress > 0.4 ? Colors.white : const Color(0xFF9E7BFF),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildHealthScoreCard(BuildContext context, UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Good',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 4),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 4,
                        backgroundColor: Colors.transparent,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      '7/10',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _buildHealthMetricRow('Fiber', '6g', 0.6, const Color(0xFF9E7BFF)),
          const SizedBox(height: 12),
          _buildHealthMetricRow('Net Carbs', '66g', 0.45, const Color(0xFFC084FC)),
          const SizedBox(height: 12),
          _buildHealthMetricRow('Sugar', '20g', 0.25, const Color(0xFFFF5252)),
          const SizedBox(height: 12),
          _buildHealthMetricRow('Sodium', '1244mg', 0.55, const Color(0xFFFF9800)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildHealthMetricRow(String label, String value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBurnedCaloriesCard(BuildContext context, UserProvider provider) {
    final consumed = provider.totalConsumedCalories;
    final burned = provider.burnedCalories;
    final net = provider.netCalories;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B6B), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Calorie Balance',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceColumn(
                  'Intake',
                  '$consumed',
                  'kcal',
                  const Color(0xFFF79E74),
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _buildBalanceColumn(
                  'Burnt',
                  '$burned',
                  'kcal',
                  const Color(0xFFFF6B6B),
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _buildBalanceColumn(
                  'Net',
                  '$net',
                  'kcal',
                  net >= 0 ? const Color(0xFF4ECDC4) : const Color(0xFF00B894),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08);
  }

  Widget _buildBalanceColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$label ($unit)',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class CalorieGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color baseColor;
  final Color progressColor;

  CalorieGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.baseColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2 - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint paintBase = Paint()
      ..color = baseColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint paintProgress = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Base circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      paintBase,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant CalorieGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class WaterWaveClipper extends CustomClipper<Path> {
  final double progress;

  WaterWaveClipper(this.progress);

  @override
  Path getClip(Size size) {
    final double h = size.height * (1.0 - progress);
    final Path path = Path()
      ..lineTo(0, h)
      ..cubicTo(
        size.width * 0.25,
        h - 4,
        size.width * 0.75,
        h + 4,
        size.width,
        h,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaterWaveClipper oldClipper) => oldClipper.progress != progress;
}
