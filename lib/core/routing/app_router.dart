import 'package:deltamind/features/auth/login_page.dart';
import 'package:deltamind/features/auth/register_page.dart';
import 'package:deltamind/features/dashboard/dashboard_page.dart';
import 'package:deltamind/features/gamification/achievements_page.dart';
import 'package:deltamind/features/history/history_page.dart';
import 'package:deltamind/features/history/quiz_review_detail_page.dart';
import 'package:deltamind/features/onboarding/onboarding_page.dart';
import 'package:deltamind/features/profile/profile_page.dart';
import 'package:deltamind/features/quiz/create_quiz_page.dart';
import 'package:deltamind/features/quiz/quiz_list_page.dart';
import 'package:deltamind/features/quiz/take_quiz_page.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App routes constants
class AppRoutes {
  /// Root route
  static const String root = '/';

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

  /// History route
  static const String history = '/history';

  /// Quiz review detail route
  static const String quizReviewDetail = '/quiz-review/:id';

  /// Achievements route
  static const String achievements = '/achievements';
}

/// App router configuration
final List<GoRoute> appRoutes = [
  GoRoute(path: AppRoutes.root, redirect: (_, __) => AppRoutes.onboarding),
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
    path: AppRoutes.createQuiz,
    builder: (context, state) => const CreateQuizPage(),
  ),
  GoRoute(
    path: AppRoutes.history,
    builder: (context, state) => const HistoryPage(),
  ),
  GoRoute(
    path: AppRoutes.achievements,
    builder: (context, state) => const AchievementsPage(),
  ),
  GoRoute(
    path: '/quiz-review/:id',
    builder: (context, state) {
      final attemptId = state.pathParameters['id']!;
      return QuizReviewDetailPage(attemptId: attemptId);
    },
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
                child: Text('Error loading quiz: ${quizSnapshot.error}'),
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

              if (questionsSnapshot.hasError || !questionsSnapshot.hasData) {
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
];
