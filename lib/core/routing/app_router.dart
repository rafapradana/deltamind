import 'package:deltamind/core/routing/scaffold_with_navbar.dart';
import 'package:deltamind/features/analytics/analytics_page.dart';
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
import 'package:deltamind/features/history/history_page.dart';
import 'package:deltamind/features/history/quiz_review_detail_page.dart';
import 'package:deltamind/features/learning_paths/learning_paths_page.dart';
import 'package:deltamind/features/learning_paths/learning_path_detail_page.dart';
import 'package:deltamind/features/notes/create_edit_note_page.dart';
import 'package:deltamind/features/notes/notes_list_page.dart';
import 'package:deltamind/features/onboarding/onboarding_page.dart';
import 'package:deltamind/features/profile/profile_page.dart';
import 'package:deltamind/features/quiz/create_quiz_page.dart';
import 'package:deltamind/features/quiz/quiz_list_page.dart';
import 'package:deltamind/features/quiz/take_quiz_page.dart';
import 'package:deltamind/features/search/search_page.dart';
import 'package:deltamind/features/splash/splash_screen.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App routes constants
class AppRoutes {
  /// Root route
  static const String root = '/';

  /// Splash route
  static const String splash = '/splash';

  /// Onboarding route
  static const String onboarding = '/onboarding';

  /// Login route
  static const String login = '/login';

  /// Register route
  static const String register = '/register';

  /// Dashboard route
  static const String dashboard = '/dashboard';

  /// Profile route
  static const String profile = '/profile';

  /// Quiz list route
  static const String quizList = '/quizzes';

  /// Create quiz route
  static const String createQuiz = '/create-quiz';

  /// Take quiz route
  static const String takeQuiz = '/quiz/:id';

  /// Quiz review detail route
  static const String quizReviewDetail = '/quiz-review/:id';

  /// Achievements route
  static const String achievements = '/achievements';

  /// Analytics route
  static const String analytics = '/analytics';

  /// Streak freeze route
  static const String streakFreeze = '/streak-freeze';

  /// Search route
  static const String search = '/search';

  /// Notes list route
  static const String notesList = '/notes';

  /// Create note route
  static const String createNote = '/notes/create';

  /// Edit note route
  static const String editNote = '/notes/:id';

  /// Flashcards list route
  static const String flashcardsList = '/flashcards';

  /// Create flashcard deck route
  static const String createFlashcardDeck = '/flashcards/create';

  /// Flashcard deck detail route
  static const String flashcardDeckDetail = '/flashcards/:id';

  /// Flashcard viewer route
  static const String flashcardViewer = '/flashcards/:deckId/view';

  /// Learning paths route
  static const String learningPaths = '/learning-paths';

  /// Learning path detail route
  static const String learningPathDetail = '/learning-paths/:id';
}

/// App router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If the user is not logged in, redirect to the login page
      // unless they are already on the login page
      final loginLocation = state.matchedLocation == AppRoutes.login;
      final splashLocation = state.matchedLocation == AppRoutes.splash;

      if (authState.user == null && !loginLocation && !splashLocation) {
        return AppRoutes.login;
      }

      // If the user is logged in and on the login page, redirect to the home page
      if (authState.user != null && loginLocation) {
        return AppRoutes.dashboard;
      }

      // No redirect
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => AppRoutes.splash,
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
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

      // Shell route for the main navigation
      ShellRoute(
        builder: (context, state, child) {
          // Determine which tab is active based on the location
          int selectedIndex = 0;
          if (state.matchedLocation.startsWith(AppRoutes.learningPaths)) {
            selectedIndex = 1;
          } else if (state.matchedLocation.startsWith(AppRoutes.quizList) ||
              state.matchedLocation.startsWith('/quiz/') ||
              state.matchedLocation.startsWith('/quiz-review/')) {
            selectedIndex = 2;
          } else if (state.matchedLocation.startsWith(AppRoutes.achievements)) {
            selectedIndex = 3;
          }

          return ScaffoldWithNavBar(
            selectedIndex: selectedIndex,
            child: child,
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),

          // Learning Paths
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

          // Quizzes
          GoRoute(
            path: AppRoutes.quizList,
            builder: (context, state) => const QuizListPage(),
          ),
          GoRoute(
            path: '/quiz/:id',
            builder: (context, state) {
              final quizId = state.pathParameters['id']!;

              return FutureBuilder<Quiz>(
                future: QuizService.getQuizById(quizId),
                builder: (context, quizSnapshot) {
                  if (quizSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (quizSnapshot.hasError || !quizSnapshot.hasData) {
                    return Scaffold(
                      body: Center(
                        child:
                            Text('Error loading quiz: ${quizSnapshot.error}'),
                      ),
                    );
                  }

                  final quiz = quizSnapshot.data!;

                  return FutureBuilder<List<Question>>(
                    future: QuizService.getQuestionsForQuiz(quizId),
                    builder: (context, questionsSnapshot) {
                      if (questionsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (questionsSnapshot.hasError ||
                          !questionsSnapshot.hasData) {
                        return Scaffold(
                          body: Center(
                            child: Text(
                              'Error loading questions: ${questionsSnapshot.error}',
                            ),
                          ),
                        );
                      }

                      final questions = questionsSnapshot.data!;

                      if (questions.isEmpty) {
                        return Scaffold(
                          appBar: AppBar(title: Text(quiz.title)),
                          body: const Center(
                            child: Text('This quiz has no questions yet.'),
                          ),
                        );
                      }

                      return TakeQuizPage(
                        quizId: quizId,
                        quizTitle: quiz.title,
                        questions: questions,
                      );
                    },
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/quiz-review/:id',
            builder: (context, state) {
              final attemptId = state.pathParameters['id']!;
              return QuizReviewDetailPage(attemptId: attemptId);
            },
          ),

          // Achievements
          GoRoute(
            path: AppRoutes.achievements,
            builder: (context, state) => const AchievementsPage(),
          ),
        ],
      ),

      // Other standalone routes
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.createQuiz,
        builder: (context, state) => const CreateQuizPage(),
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
        path: AppRoutes.search,
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
        path: '/notes/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return CreateEditNotePage(noteId: noteId);
        },
      ),
    ],
  );
});
