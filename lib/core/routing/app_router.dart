// No imports needed as this file only contains route constants

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
