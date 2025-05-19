import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/features/auth/login_page.dart';
import 'package:deltamind/features/auth/register_page.dart';
import 'package:deltamind/features/dashboard/dashboard_page.dart';
import 'package:deltamind/features/flashcards/create_flashcard_deck_page.dart';
import 'package:deltamind/features/flashcards/flashcard_deck_detail_page.dart';
import 'package:deltamind/features/flashcards/flashcard_viewer_page.dart';
import 'package:deltamind/features/flashcards/flashcards_list_page.dart';
import 'package:deltamind/features/gamification/achievements_page.dart';
import 'package:deltamind/features/gamification/streak_freeze_page.dart';
import 'package:deltamind/features/learning_paths/learning_paths_page.dart';
import 'package:deltamind/features/learning_paths/learning_path_detail_page.dart';
import 'package:deltamind/features/navigation/scaffold_with_nav_bar.dart';
import 'package:deltamind/features/notes/notes_list_page.dart';
import 'package:deltamind/features/notes/create_edit_note_page.dart';
import 'package:deltamind/features/onboarding/onboarding_page.dart';
import 'package:deltamind/features/profile/profile_page.dart';
import 'package:deltamind/features/quiz/create_quiz_page.dart';
import 'package:deltamind/features/quiz/quiz_list_page.dart';
import 'package:deltamind/features/quiz/take_quiz_page.dart';
import 'package:deltamind/features/reviews/reviews_page.dart';
import 'package:deltamind/features/history/history_page.dart';
import 'package:deltamind/features/history/quiz_review_detail_page.dart';
import 'package:deltamind/features/splash/splash_screen.dart';
import 'package:deltamind/features/analytics/analytics_page.dart';
import 'package:deltamind/features/search/search_page.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/onboarding_service.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:deltamind/core/routing/auth_middleware.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  try {
    // Load .env file first
    await dotenv.load();

    // Add a small delay to ensure environment variables are properly loaded
    await Future.delayed(const Duration(milliseconds: 500));

    // Initialize Supabase with proper error handling
    await SupabaseService.initialize().catchError((error) {
      debugPrint('Failed to initialize Supabase: $error');
      // Rethrow to be caught by the outer try-catch
      throw error;
    });

    // Initialize other services
    await GeminiService.initialize();
    
    // Uncomment for testing onboarding
    // await OnboardingService.resetOnboardingStatus();
    // debugPrint('Onboarding status reset for testing purposes');

    // Add another small delay to ensure all services are initialized
    await Future.delayed(const Duration(milliseconds: 500));

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    debugPrint('Critical error initializing services: $e');
    // Show an error UI instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Failed to initialize the app',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Please check your internet connection and restart the app.',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// App router provider
final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  // Create a router notifier to handle authentication state changes
  // This ensures authentication state is properly reflected in navigation
  final _routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable:
        _routerNotifier, // Refresh routes when auth state changes
    redirect: (BuildContext context, GoRouterState state) {
      // Skip redirection for splash screen
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;
      if (isSplashRoute) {
        return null;
      }

      final isLoggedIn = authState.user != null;
      debugPrint('GoRouter redirect check: isLoggedIn=$isLoggedIn, path=${state.matchedLocation}');
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isRegisterRoute = state.matchedLocation == AppRoutes.register;

      // Define which routes are public (don't require authentication)
      final isPublicRoute = isLoginRoute || isRegisterRoute;

      // If we're currently loading auth state, don't redirect
      if (authState.isLoading) {
        return null;
      }

      // If we're at the splash screen, let it handle navigation
      if (state.matchedLocation == AppRoutes.splash) {
        return null;
      }

      // If the user is not logged in and is not on a public route, redirect to login
      if (!isLoggedIn && !isPublicRoute) {
        debugPrint(
            'Redirecting unauthenticated user to login from ${state.matchedLocation}');
        return AppRoutes.login;
      }

      // If the user is logged in and is on a public route, redirect to dashboard
      if (isLoggedIn && isPublicRoute) {
        debugPrint(
            'Redirecting authenticated user to dashboard from ${state.matchedLocation}');
        return AppRoutes.dashboard;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Public routes (no navigation bar)
      GoRoute(path: AppRoutes.root, redirect: (_, __) => AppRoutes.splash),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
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
        builder: (context, state, child) => ScaffoldWithNavBar(
          child: AuthMiddleware(child: child),
        ),
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
            path: AppRoutes.learningPaths,
            builder: (context, state) => const LearningPathsPage(),
          ),
          GoRoute(
            path: '/learning-paths/:id',
            builder: (context, state) {
              final pathId = state.pathParameters['id']!;
              return LearningPathDetailPage(pathId: pathId);
            },
          ),
          GoRoute(
            path: AppRoutes.quizList,
            builder: (context, state) {
              final extra = state.extra;
              int initialTabIndex = 0;
              if (extra != null && extra is int) {
                initialTabIndex = extra;
              }
              return QuizListPage(initialTabIndex: initialTabIndex);
            },
          ),
          GoRoute(
            path: AppRoutes.createQuiz,
            builder: (context, state) => const CreateQuizPage(),
          ),
          GoRoute(
            path: AppRoutes.achievements,
            builder: (context, state) => const AchievementsPage(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: AppRoutes.streakFreeze,
            builder: (context, state) => const StreakFreezePage(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: AppRoutes.notesList,
            builder: (context, state) => const NotesListPage(),
          ),
          GoRoute(
            path: AppRoutes.createNote,
            builder: (context, state) {
              return const CreateEditNotePage();
            },
          ),
          GoRoute(
            path: '/notes/:id',
            builder: (context, state) {
              final noteId = state.pathParameters['id']!;
              return CreateEditNotePage(noteId: noteId);
            },
          ),
          GoRoute(
            path: AppRoutes.flashcardsList,
            builder: (context, state) => const FlashcardsListPage(),
          ),
          GoRoute(
            path: AppRoutes.createFlashcardDeck,
            builder: (context, state) => const CreateFlashcardDeckPage(),
          ),
          GoRoute(
            path: '/flashcards/:id',
            builder: (context, state) {
              final deckId = state.pathParameters['id']!;
              return FlashcardDeckDetailPage(deckId: deckId);
            },
          ),
          GoRoute(
            path: '/flashcards/:deckId/view',
            builder: (context, state) {
              final deckId = state.pathParameters['deckId']!;
              return FlashcardViewerPage(deckId: deckId);
            },
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

/// Router notifier to handle auth state changes
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthState? _previousAuthState;

  _RouterNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Always notify on any auth state change to ensure routing is updated
      final didAuthStateChange = previous?.user != next.user;
      final isAuthLoading = next.isLoading;
      _previousAuthState = next;
      
      debugPrint('Auth state change detected: user=${next.user != null}, loading=${isAuthLoading}');
      
      // Notify immediately on auth state change or loading state change
      notifyListeners();
    });
  }
}

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
