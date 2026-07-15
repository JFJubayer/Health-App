import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/meal_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  int _step = 0; // 0: Onboarding, 1: Scanning Animation, 2: Scan Results
  Timer? _scanTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _step = 1;
    });

    _scanTimer = Timer(const Duration(seconds: 4), () {
      setState(() {
        _step = 2;
      });
    });
  }

  void _resetScan() {
    setState(() {
      _step = 0;
    });
  }

  void _logScannedMeal(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Create a mock scanned meal
    final scannedMeal = MealModel(
      id: 'scanned_meal_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI Scanned Veggie Plate',
      calories: 370, // 170 + 90 + 110
      type: MealType.lunch,
      protein: 12.0,
      carbs: 45.0,
      fat: 8.0,
      ingredients: ['Cabbage', 'Orange', 'Broccoli'],
      instructions: 'AI Scanned fresh plate.',
      prepTimeMinutes: 5,
      isConsumed: true,
    );

    userProvider.addCustomMeal(scannedMeal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged "AI Scanned Veggie Plate" (370 kcal) to Lunch!', style: GoogleFonts.outfit()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _step = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5EFEB),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/scan_onboarding_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark Overlay for scanning mode
          if (_step == 1)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),

          // Dynamic Island Notch mockup for visual styling
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 110,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          // Back Button if not in onboarding
          if (_step > 0)
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: _resetScan,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
              ),
            ),

          // STEP 0: ONBOARDING OVERLAY & TAGS
          if (_step == 0) ...[
            // Connector Lines Painter
            Positioned.fill(
              child: CustomPaint(
                painter: _ConnectorLinesPainter(
                  size: size,
                  showCabbage: true,
                  showOrange: true,
                  showBroccoli: true,
                ),
              ),
            ),

            // Floating Tags
            // Cabbage Tag (170 kcal)
            Positioned(
              left: size.width * 0.08,
              top: size.height * 0.16,
              child: _buildFloatingTag('170 kkal'),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),

            // Orange Tag (90 kcal)
            Positioned(
              left: size.width * 0.44,
              top: size.height * 0.24,
              child: _buildFloatingTag('90 kkal'),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: -0.1),

            // Broccoli Tag (110 kcal)
            Positioned(
              right: size.width * 0.08,
              top: size.height * 0.16,
              child: _buildFloatingTag('110 kkal'),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: -0.1),

            // Onboarding Bottom Sheet
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your Food,',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Decoded By AI',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'From scanning to tracking - everything\nhappens automatically.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Dot indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E3F43),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _startScanning,
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ),
          ],

          // STEP 1: SCANNING MODE (CAMERA MOCK + SCAN LINE)
          if (_step == 1) ...[
            // Camera viewport guides
            Center(
              child: Container(
                width: size.width * 0.85,
                height: size.height * 0.55,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            
            // Scan Line
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final topMargin = size.height * 0.225;
                final viewportHeight = size.height * 0.55;
                final currentY = topMargin + (_animationController.value * viewportHeight);
                return Positioned(
                  top: currentY,
                  left: size.width * 0.08,
                  right: size.width * 0.08,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Scanning overlay text
            Positioned(
              top: size.height * 0.15,
              left: 20,
              right: 20,
              child: Center(
                child: Text(
                  'ANALYZING PLATE...',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).fadeOut(duration: 800.ms, curve: Curves.easeInOut),
              ),
            ),
          ],

          // STEP 2: SCAN RESULTS
          if (_step == 2) ...[
            // Overlay targets with boxes
            Positioned(
              left: size.width * 0.25,
              top: size.height * 0.32,
              child: _buildScannedObjectBox(size.width * 0.35, size.width * 0.35, 'CABBAGE (170 kcal)'),
            ).animate().scale(),

            Positioned(
              left: size.width * 0.38,
              top: size.height * 0.44,
              child: _buildScannedObjectBox(size.width * 0.28, size.width * 0.28, 'ORANGE (90 kcal)'),
            ).animate().scale(delay: 200.ms),

            Positioned(
              left: size.width * 0.52,
              top: size.height * 0.55,
              child: _buildScannedObjectBox(size.width * 0.26, size.width * 0.26, 'BROCCOLI (110 kcal)'),
            ).animate().scale(delay: 400.ms),

            // Scan Results Panel
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scan Complete!',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildResultRow('🥬 Cabbage (Fresh Raw)', '170 kcal'),
                    _buildResultRow('🍊 Orange Slice', '90 kcal'),
                    _buildResultRow('🥦 Broccoli Florets', '110 kcal'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Calories Detected:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('370 kcal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _resetScan,
                            child: Text('Retake', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => _logScannedMeal(context),
                            child: Text(
                              'Log Meal',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildScannedObjectBox(double w, double h, String label) {
    final theme = Theme.of(context);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String food, String cal) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(food, style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          Text(cal, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, fontSize: 13)),
        ],
      ),
    );
  }
}

// Custom Painter to draw connector lines in Onboarding Screen
class _ConnectorLinesPainter extends CustomPainter {
  final Size size;
  final bool showCabbage;
  final bool showOrange;
  final bool showBroccoli;

  _ConnectorLinesPainter({
    required this.size,
    required this.showCabbage,
    required this.showOrange,
    required this.showBroccoli,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Helper to draw dotted connector line
    void drawDottedLine(Offset p1, Offset p2) {
      const double dashWidth = 4;
      const double dashSpace = 4;
      double distance = (p2 - p1).distance;
      Offset direction = (p2 - p1) / distance;
      double currentDist = 0;

      while (currentDist < distance) {
        canvas.drawCircle(p1 + direction * currentDist, 0.8, paint);
        currentDist += dashWidth + dashSpace;
      }
    }

    // Cabbage: From Tag bottom/center to Cabbage center
    if (showCabbage) {
      final tagOffset = Offset(size.width * 0.16, size.height * 0.205);
      final targetOffset = Offset(size.width * 0.40, size.height * 0.38);
      drawDottedLine(tagOffset, targetOffset);
      canvas.drawCircle(targetOffset, 4, dotPaint);
    }

    // Orange: From Tag bottom/center to Orange slice center
    if (showOrange) {
      final tagOffset = Offset(size.width * 0.52, size.height * 0.285);
      final targetOffset = Offset(size.width * 0.50, size.height * 0.48);
      drawDottedLine(tagOffset, targetOffset);
      canvas.drawCircle(targetOffset, 4, dotPaint);
    }

    // Broccoli: From Tag bottom/center to Broccoli center
    if (showBroccoli) {
      final tagOffset = Offset(size.width * 0.83, size.height * 0.205);
      final targetOffset = Offset(size.width * 0.60, size.height * 0.60);
      drawDottedLine(tagOffset, targetOffset);
      canvas.drawCircle(targetOffset, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
