import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Show loading indicator while checking auth state
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Redirect to login if not authenticated
    if (authState.user == null) {
      return const LoginPage();
    }

    // User is authenticated, show the requested page
    return child;
  }
} 