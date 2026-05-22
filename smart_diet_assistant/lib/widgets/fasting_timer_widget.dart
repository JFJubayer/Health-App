import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

class FastingTimerWidget extends StatefulWidget {
  const FastingTimerWidget({super.key});

  @override
  State<FastingTimerWidget> createState() => _FastingTimerWidgetState();
}

class _FastingTimerWidgetState extends State<FastingTimerWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context, UserProvider provider) {
    int tempDuration = provider.fastingDurationHours;
    int tempOffset = provider.fastingReminderOffset;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Fasting Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fasting Goal', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: tempDuration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [12, 14, 16, 18, 20].map((hours) {
                      return DropdownMenuItem(
                        value: hours,
                        child: Text('$hours Hours', style: GoogleFonts.outfit()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempDuration = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Reminder', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: tempOffset,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At time of end')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                      DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempOffset = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                  ElevatedButton(
                    onPressed: () {
                      provider.setFastingSettings(
                        durationHours: tempDuration,
                        reminderOffsetMinutes: tempOffset,
                      );
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final isFasting = provider.isFasting;
    
    double progress = 0.0;
    String timeDisplay = '00:00';
    String statusText = 'Ready to start';
    
    if (isFasting && provider.fastingStartTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(provider.fastingStartTime!);
      final totalDuration = Duration(hours: provider.fastingDurationHours);
      
      progress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
      
      if (elapsed < totalDuration) {
        final remaining = totalDuration - elapsed;
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes.remainder(60);
        timeDisplay = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
        statusText = 'Remaining';
      } else {
        progress = 1.0;
        final overtime = elapsed - totalDuration;
        final hours = overtime.inHours;
        final minutes = overtime.inMinutes.remainder(60);
        timeDisplay = '+${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
        statusText = 'Goal Reached!';
      }
    } else {
      timeDisplay = '${provider.fastingDurationHours}h';
      statusText = 'Goal';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
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
                    'Intermittent Fasting',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    isFasting ? 'Fasting Window' : 'Eating Window',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () => _showSettingsDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Theme.of(context).brightness == Brightness.light ? const Color(0xFFF3F4F6) : Colors.grey[800]!,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Theme.of(context).colorScheme.primary : const Color(0xFF8B5CF6)
                      ),
                      strokeCap: StrokeCap.round,
                    ).animate(target: isFasting ? 1 : 0).fadeIn(duration: 400.ms),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeDisplay,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: progress >= 1.0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (isFasting) {
                  provider.endFasting();
                } else {
                  provider.startFasting();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFasting ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF8B5CF6),
                foregroundColor: isFasting ? const Color(0xFFEF4444) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isFasting ? 'End Fast' : 'Start Fasting',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
