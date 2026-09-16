import 'package:flutter/material.dart';
import 'food_selection_screen.dart';
import 'active_orders_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class StudentNavigationWrapper extends StatefulWidget {
  const StudentNavigationWrapper({super.key});

  @override
  State<StudentNavigationWrapper> createState() => _StudentNavigationWrapperState();
}

class _StudentNavigationWrapperState extends State<StudentNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FoodSelectionScreen(),
    const ActiveOrdersScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          _buildFloatingNavBar(),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4b652a).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFF4b652a).withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.restaurant_menu, 'Menu'),
            _buildNavItem(1, Icons.shopping_bag, 'Orders'),
            _buildNavItem(2, Icons.history, 'History'),
            _buildNavItem(3, Icons.account_circle, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4b652a).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4b652a) : const Color(0xFF94a3b8),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? const Color(0xFF4b652a) : const Color(0xFF94a3b8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
