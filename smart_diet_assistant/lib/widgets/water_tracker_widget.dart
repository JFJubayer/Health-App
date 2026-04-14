import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

class WaterTrackerWidget extends StatelessWidget {
  const WaterTrackerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final progress = (provider.waterIntake / provider.waterGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                    'Hydration',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'Daily goal: ${provider.waterGoal}ml',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 140,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Water Level
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: 800.ms,
                          height: 140 * progress,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                            ),
                          ),
                        ).animate(target: progress).shimmer(
                          duration: 2.seconds,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Wave overlay (Simplified animation)
                      Positioned(
                        bottom: (140 * progress) - 10,
                        left: 0,
                        right: 0,
                        child: progress > 0 && progress < 1
                            ? Icon(
                                Icons.waves,
                                color: Colors.white.withOpacity(0.3),
                                size: 40,
                              ).animate(onPlay: (controller) => controller.repeat()).moveX(
                                    begin: -20,
                                    end: 20,
                                    duration: 2.seconds,
                                  )
                            : const SizedBox.shrink(),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${provider.waterIntake}',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: progress > 0.5 ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'ml',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: progress > 0.5 ? Colors.white70 : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildAddButton(context, provider, 250, 'Glass'),
                    const SizedBox(height: 12),
                    _buildAddButton(context, provider, 500, 'Bottle'),
                    const SizedBox(height: 12),
                    IconButton(
                      onPressed: () => provider.resetWater(),
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      tooltip: 'Reset Daily Intake',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, UserProvider provider, int amount, String label) {
    return GestureDetector(
      onTap: () => provider.addWater(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.add, color: Color(0xFF3B82F6), size: 20),
              Text(
                '+$amount ml',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale();
  }
}
