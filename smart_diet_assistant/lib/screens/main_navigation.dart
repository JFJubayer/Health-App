import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'meals_screen.dart';
import 'profile_screen.dart';
import 'shopping_list_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MealsScreen(),
    const ShoppingListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF059669).withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildDestination(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Overview'),
          _buildDestination(Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Diet Plan'),
          _buildDestination(Icons.shopping_basket_outlined, Icons.shopping_basket_rounded, 'Shopping'),
          _buildDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
        ],
      ),
    );
  }

  Widget _buildDestination(IconData icon, IconData selectedIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: const Color(0xFF6B7280)),
      selectedIcon: Icon(selectedIcon, color: const Color(0xFF059669)),
      label: label,
    );
  }
}

