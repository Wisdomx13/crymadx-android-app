import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../navigation/app_router.dart';

/// Main Screen with Bottom Navigation
class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/main/home')) return 0;
    if (location.startsWith('/main/markets')) return 1;
    if (location.startsWith('/main/trade')) return 2;
    if (location.startsWith('/main/assets')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.markets);
        break;
      case 2:
        context.go(AppRoutes.trade);
        break;
      case 3:
        context.go(AppRoutes.assets);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
              color: isDark ? null : Colors.white.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.lightGlassBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Top reflection line (dark mode only)
                if (isDark)
                  Positioned(
                    top: 0,
                    left: 40,
                    right: 40,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: SizedBox(
                    height: 65,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Home',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onItemTapped(context, 0),
                        ),
                        _NavItem(
                          icon: Icons.show_chart_outlined,
                          activeIcon: Icons.show_chart,
                          label: 'Markets',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onItemTapped(context, 1),
                        ),
                        _NavItem(
                          icon: Icons.swap_horiz,
                          activeIcon: Icons.swap_horiz,
                          label: 'Trade',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onItemTapped(context, 2),
                        ),
                        _NavItem(
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet,
                          label: 'Assets',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onItemTapped(context, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final unselectedColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glass container when selected (pure white glow, no green)
            isDark && isSelected
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      activeIcon,
                      size: 22,
                      color: selectedColor,
                    ),
                  )
                : Icon(
                    isSelected ? activeIcon : icon,
                    size: 24,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
