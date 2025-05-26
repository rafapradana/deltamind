import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Middleware to check if user is authenticated before allowing access to protected routes
class AuthMiddleware extends ConsumerWidget {
  final Widget child;

  const AuthMiddleware({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Handle loading state
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle unauthenticated state
    if (authState.user == null) {
      // Immediately redirect to login without waiting for post frame callback
      // this ensures faster redirect to login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if we're not already on the login page
        final currentLocation = GoRouterState.of(context).matchedLocation;
        if (currentLocation != AppRoutes.login &&
            currentLocation != AppRoutes.register &&
            currentLocation != AppRoutes.onboarding &&
            currentLocation != AppRoutes.splash) {
          debugPrint(
              'Redirecting to login from $currentLocation due to unauthenticated state');
          GoRouter.of(context).go(AppRoutes.login);
        }
      });

      // Show a loading screen while we're waiting to navigate
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Redirecting to login...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
            ],
          ),
        ),
      );
    }

    // User is authenticated, show the child widget
    return child;
  }
}
