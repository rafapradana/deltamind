import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Splash screen displayed when the app starts
class SplashScreen extends ConsumerStatefulWidget {
  /// Default constructor
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create fade-in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation
    _animationController.forward();

    // Navigate to appropriate screen after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    // First check if user has seen onboarding
    final hasCompletedOnboarding = await OnboardingService.hasCompletedOnboarding();

    // If not, show onboarding first
    if (!hasCompletedOnboarding) {
      if (mounted) {
        context.go(AppRoutes.onboarding);
        return;
      }
    }

    // Then check if user is logged in
    final authState = ref.read(authControllerProvider);
    final isLoggedIn = authState.user != null;

    if (isLoggedIn) {
      // Navigate to dashboard if already logged in
      if (mounted) context.go(AppRoutes.dashboard);
    } else {
      // Navigate to login if not logged in
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logos/deltamind-white.png',
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
