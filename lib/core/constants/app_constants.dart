/// App constants
class AppConstants {
  /// App name
  static const String appName = 'DeltaMind';
  
  /// App version
  static const String appVersion = '1.0.0';
  
  /// App description
  static const String appDescription = 'Learn and memorize effectively with AI-generated quizzes and spaced repetition';
  
  /// Copyright text
  static const String copyright = '© 2025 DeltaMind';
  
  /// Quiz types
  static const List<String> quizTypes = [
    'Multiple Choice',
    'True/False',
    'Fill in the Blank',
  ];
  
  /// Quiz difficulties
  static const List<String> quizDifficulties = [
    'Easy',
    'Medium',
    'Hard',
  ];
  
  /// Default question count
  static const int defaultQuestionCount = 5;
  
  /// Maximum question count
  static const int maxQuestionCount = 20;
  
  /// Minimum text content length for quiz generation
  static const int minContentLength = 100;
  
  /// Maximum text content length for quiz generation (to prevent token limit issues)
  static const int maxContentLength = 5000;
} 