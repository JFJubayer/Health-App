import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'meals_screen.dart';
import 'scan_screen.dart';
import 'workouts_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MealsScreen(),
    const ScanScreen(),
    const WorkoutsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating navigation bar
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3E3F43), // Premium charcoal dark grey from design
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(0, Icons.home_filled, Icons.home_outlined),
              _buildNavButton(1, Icons.menu_book_rounded, Icons.menu_book_outlined),
              _buildCenterScanButton(),
              _buildNavButton(3, Icons.fitness_center_rounded, Icons.fitness_center_outlined),
              _buildNavButton(4, Icons.settings_rounded, Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData selectedIcon, IconData unselectedIcon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? const Color(0xFFF79E74) : Colors.white70, // Peach active, white inactive
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCenterScanButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF79E74), // Primary orange/peach color from design
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF79E74).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.center_focus_weak_rounded, // Viewport scanner icon from design
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

