import 'package:flutter/material.dart';
import 'package:canteen_app/screens/owner/store_owner_dashboard_screen.dart';
import 'package:canteen_app/screens/owner/owner_orders_screen.dart';
import 'package:canteen_app/screens/owner/owner_analytics_screen.dart';
import 'package:canteen_app/screens/owner/owner_profile_screen.dart';

class OwnerNavigationWrapper extends StatefulWidget {
  const OwnerNavigationWrapper({super.key});

  @override
  State<OwnerNavigationWrapper> createState() => _OwnerNavigationWrapperState();
}

class _OwnerNavigationWrapperState extends State<OwnerNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StoreOwnerDashboardScreen(),
    const OwnerOrdersScreen(),
    const OwnerAnalyticsScreen(),
    const OwnerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF191d15),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
            _buildNavItem(1, Icons.receipt_long_rounded, 'Orders'),
            _buildNavItem(2, Icons.analytics_rounded, 'Analytics'),
            _buildNavItem(3, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4b652a) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
