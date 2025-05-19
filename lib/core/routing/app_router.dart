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
