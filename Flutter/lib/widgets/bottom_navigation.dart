import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            activeIcon: Icon(Icons.home_work),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            activeIcon: Icon(Icons.gavel),
            label: 'Auctions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
