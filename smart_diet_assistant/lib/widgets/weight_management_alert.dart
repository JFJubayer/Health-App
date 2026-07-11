import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/health_service.dart';
import 'glass_card.dart';

class WeightManagementAlert extends StatefulWidget {
  final UserProvider userProvider;

  const WeightManagementAlert({
    super.key,
    required this.userProvider,
  });

  @override
  State<WeightManagementAlert> createState() => _WeightManagementAlertState();
}

class _WeightManagementAlertState extends State<WeightManagementAlert> {
  bool _showTips = false;

  Color _getBmiColor(String category) {
    if (category == 'Overweight') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userProvider.user;
    if (user == null) return const SizedBox.shrink();

    final bmi = HealthService.calculateBMI(user.weightKg, user.heightCm);
    if (bmi < 25.0) return const SizedBox.shrink(); // Hide if BMI is normal/underweight

    final category = HealthService.getBMICategory(bmi);
    final isEnabled = user.weightManagementEnabled;
    final currentDeficit = user.weightDeficitCal;
    final theme = Theme.of(context);
    final bmiColor = _getBmiColor(category);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Toggle switch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.scale_rounded,
                  color: bmiColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Management',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'BMI: ${bmi.toStringAsFixed(1)} ($category)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  final updatedUser = user.copyWith(
                    weightManagementEnabled: value,
                  );
                  widget.userProvider.updateUserProfile(updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Weight Loss Plan activated!'
                            : 'Weight Loss Plan deactivated (Maintenance Mode active).',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                activeThumbColor: Colors.white,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Core status message
          Text(
            isEnabled
                ? 'Your BMI is above the safe level (18.5 - 24.9). We have automatically tailored your meal recommendations to a customized calorie deficit of -${currentDeficit.toInt()} kcal/day to help you reach a healthy weight.'
                : 'Your BMI is above the safe level (18.5 - 24.9). Weight Management is currently disabled. Toggle the switch above to activate a weight-loss plan.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          if (isEnabled) ...[
            const SizedBox(height: 20),
            
            // Customization Options (Calorie Deficit ChoiceChips)
            Text(
              'Customize Target Deficit:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [250.0, 500.0, 750.0].map((deficit) {
                final isSelected = currentDeficit == deficit;
                return ChoiceChip(
                  label: Text(
                    '-${deficit.toInt()} kcal',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      final updatedUser = user.copyWith(
                        weightDeficitCal: deficit,
                      );
                      widget.userProvider.updateUserProfile(updatedUser);
                    }
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Tips & Advice Expandable Panel
          InkWell(
            onTap: () => setState(() => _showTips = !_showTips),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Diet Tips for Weight Loss',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showTips ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          if (_showTips) ...[
            const SizedBox(height: 12),
            _buildTipRow(context, '💧 Drink water before meals to naturally reduce calorie intake.'),
            const SizedBox(height: 8),
            _buildTipRow(context, '🥚 Prioritize protein and fiber; they promote fullness and preserve muscle.'),
            const SizedBox(height: 8),
            _buildTipRow(context, '🍽️ Control portion sizes: use smaller plates and avoid seconds.'),
            const SizedBox(height: 8),
            _buildTipRow(context, '🥤 Limit liquid calories: avoid sugary drinks, soda, and sweet tea.'),
          ].animate().fadeIn(duration: 200.ms).slideY(begin: -0.05),
        ],
      ),
    );
  }

  Widget _buildTipRow(BuildContext context, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 8.0),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            tip,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
