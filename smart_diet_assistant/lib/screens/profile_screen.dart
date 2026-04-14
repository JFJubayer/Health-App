import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import 'input_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      user.gender == 'Male' ? Icons.face_rounded : Icons.face_3_rounded,
                      size: 60,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Welcome Back!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
            ),
            Text(
              'Your health summary is updated daily',
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileTile(Icons.cake, 'Age', '${user.age} years', Colors.orange),
                  _buildProfileTile(Icons.monitor_weight, 'Weight', '${user.weightKg.toStringAsFixed(1)} kg', Colors.green),
                  _buildProfileTile(Icons.height, 'Height', '${user.heightCm.toInt()} cm', Colors.blue),
                  _buildProfileTile(Icons.person_outline, 'Gender', user.gender, Colors.purple),
                  if (user.conditions.isNotEmpty)
                    _buildProfileTile(Icons.medical_information, 'Conditions', user.conditions.join(', '), Colors.red, isLast: true),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
                    child: Text(
                      'Preferences',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280)),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 20),
                    ),
                    title: Text('Smart Hydration Reminders', style: GoogleFonts.outfit(fontSize: 15)),
                    subtitle: Text('Actionable alerts during the day', style: GoogleFonts.outfit(fontSize: 12)),
                    trailing: Switch(
                      value: true, // We can add a setting in provider for this later
                      onChanged: (val) {
                        // Logic to enable/disable
                      },
                      activeColor: const Color(0xFF059669),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => NotificationService.showTestNotification(),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                userProvider.clearUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const InputScreen()),
                  (route) => false,
                );
              },
              child: const Text('Reset Profile & Goals'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String value, Color color, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF6B7280))),
          trailing: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.grey.withOpacity(0.05)),
          ),
      ],
    );
  }
}

