import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A scaffold with a bottom navigation bar
class ScaffoldWithNavBar extends StatefulWidget {
  /// The child widget to display
  final Widget child;

  /// Creates a [ScaffoldWithNavBar]
  const ScaffoldWithNavBar({Key? key, required this.child}) : super(key: key);

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location.startsWith(AppRoutes.dashboard)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.quizList)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.notesList)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.flashcardsList)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.quizList);
        break;
      case 2:
        context.go(AppRoutes.notesList);
        break;
      case 3:
        context.go(AppRoutes.flashcardsList);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // Always show labels for accessibility
          animationDuration: const Duration(milliseconds: 500),
          destinations: [
            _buildNavDestination(
              icon: PhosphorIconsLight.house,
              selectedIcon: PhosphorIconsFill.house,
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
            ),
            _buildNavDestination(
              icon: PhosphorIconsLight.exam,
              selectedIcon: PhosphorIconsFill.exam,
              label: 'Quizzes',
              isSelected: selectedIndex == 1,
            ),
            _buildNavDestination(
              icon: PhosphorIconsLight.notepad,
              selectedIcon: PhosphorIconsFill.notepad,
              label: 'Notes',
              isSelected: selectedIndex == 2,
            ),
            _buildNavDestination(
              icon: PhosphorIconsLight.cards,
              selectedIcon: PhosphorIconsFill.cards,
              label: 'Flashcards',
              isSelected: selectedIndex == 3,
            ),
          ],
        ),
      ),
    );
  }
  
  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            semanticLabel: '$label tab', // Add semantic label for screen readers
          ),
        ],
      ),
      selectedIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedIcon,
            size: 24,
            color: AppColors.primary,
            semanticLabel: '$label tab selected', // Enhanced semantic label
          ),
        ],
      ),
      label: label,
      tooltip: label, // Add tooltip for additional accessibility
    );
  }
}
