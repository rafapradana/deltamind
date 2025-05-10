import 'package:deltamind/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A scaffold with a bottom navigation bar that is used by the root routes
class ScaffoldWithNavBar extends StatelessWidget {
  /// Creates a scaffold with a bottom navigation bar
  const ScaffoldWithNavBar({
    Key? key,
    required this.child,
    required this.selectedIndex,
  }) : super(key: key);

  /// The child widget
  final Widget child;

  /// The selected index
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.dashboard);
              break;
            case 1:
              context.go(AppRoutes.learningPaths);
              break;
            case 2:
              context.go(AppRoutes.quizList);
              break;
            case 3:
              context.go(AppRoutes.achievements);
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular)),
            selectedIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.roadHorizon(PhosphorIconsStyle.regular)),
            selectedIcon:
                Icon(PhosphorIcons.roadHorizon(PhosphorIconsStyle.fill)),
            label: 'Learning Paths',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.exam(PhosphorIconsStyle.regular)),
            selectedIcon: Icon(PhosphorIcons.exam(PhosphorIconsStyle.fill)),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.regular)),
            selectedIcon: Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill)),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }
}
