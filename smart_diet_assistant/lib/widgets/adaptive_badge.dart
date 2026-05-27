import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdaptiveBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color? backgroundColor;
  final Color? textColor;

  const AdaptiveBadge({
    super.key,
    required this.label,
    required this.emoji,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
    final tColor = textColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tColor,
            ),
          ),
        ],
      ),
    );
  }
}
