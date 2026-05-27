import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

Future<void> showWaterGoalDialog(BuildContext context) async {
  final provider = Provider.of<UserProvider>(context, listen: false);
  double goalMl = provider.waterGoal.toDouble();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Daily Water Goal',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${goalMl.toInt()} ml',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: goalMl,
                  min: 1500,
                  max: 4000,
                  divisions: 25,
                  label: '${goalMl.toInt()} ml',
                  onChanged: (value) => setState(() => goalMl = value),
                ),
                Text(
                  'Recommended: ${(provider.user?.weightKg ?? 70) * 35} ml based on weight',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: GoogleFonts.outfit()),
              ),
              FilledButton(
                onPressed: () {
                  provider.setWaterGoal(goalMl.toInt());
                  Navigator.pop(dialogContext);
                },
                child: Text('Save', style: GoogleFonts.outfit()),
              ),
            ],
          );
        },
      );
    },
  );
}
