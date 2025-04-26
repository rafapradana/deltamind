import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/features/auth/login_page.dart';
import 'package:deltamind/features/auth/register_page.dart';
import 'package:deltamind/features/dashboard/dashboard_page.dart';
import 'package:deltamind/features/navigation/scaffold_with_nav_bar.dart';
import 'package:deltamind/features/onboarding/onboarding_page.dart';
import 'package:deltamind/features/profile/profile_page.dart';
import 'package:deltamind/features/quiz/create_quiz_page.dart';
import 'package:deltamind/features/quiz/quiz_list_page.dart';
import 'package:deltamind/features/quiz/take_quiz_page.dart';
import 'package:deltamind/features/reviews/reviews_page.dart';
import 'package:deltamind/features/history/history_page.dart';
import 'package:deltamind/features/history/quiz_review_detail_page.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  try {
    await SupabaseService.initialize();
    await GeminiService.initialize();
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// App router provider
final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If the user is not logged in, they need to be on either the
      // onboarding, login, or register page
      final isLoggedIn = authState.user != null;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isRegisterRoute = state.matchedLocation == AppRoutes.register;
      
      // If the user is not logged in and is not on a public route, redirect to onboarding
      if (!isLoggedIn && 
          !isOnboardingRoute && 
          !isLoginRoute && 
          !isRegisterRoute) {
        return AppRoutes.onboarding;
      }
      
      // If the user is logged in and is on a public route, redirect to dashboard
      if (isLoggedIn && 
          (isOnboardingRoute || isLoginRoute || isRegisterRoute)) {
        return AppRoutes.dashboard;
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Public routes (no navigation bar)
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => AppRoutes.onboarding,
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Shell route with navigation bar for authenticated routes
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.quizList,
            builder: (context, state) => const QuizListPage(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.createQuiz,
            builder: (context, state) => const CreateQuizPage(),
          ),
          GoRoute(
            path: '/quiz/:id',
            builder: (context, state) {
              final quizId = state.pathParameters['id']!;
              
              return TakeQuizPage.fromId(quizId);
            },
          ),
          GoRoute(
            path: '/quiz-review/:id',
            builder: (context, state) {
              final attemptId = state.pathParameters['id']!;
              
              return QuizReviewDetailPage(attemptId: attemptId);
            },
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
