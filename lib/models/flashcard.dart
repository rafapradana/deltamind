import 'package:uuid/uuid.dart';

/// Model for a flashcard deck
class FlashcardDeck {
  /// Deck ID
  final String id;

  /// Title of the deck
  final String title;

  /// Description of the deck
  final String? description;

  /// Source name (e.g., file name)
  final String? sourceName;

  /// Source type (e.g., pdf, txt, doc)
  final String? sourceType;

  /// Number of cards in the deck
  final int cardCount;

  /// User ID that created the deck
  final String userId;

  /// Created at timestamp
  final DateTime createdAt;

  /// Updated at timestamp
  final DateTime? updatedAt;

  /// FlashcardDeck Constructor
  const FlashcardDeck({
    required this.id,
    required this.title,
    this.description,
    this.sourceName,
    this.sourceType,
    required this.cardCount,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a new flashcard deck
  factory FlashcardDeck.create({
    required String title,
    String? description,
    String? sourceName,
    String? sourceType,
    required String userId,
  }) {
    final now = DateTime.now();
    return FlashcardDeck(
      id: const Uuid().v4(),
      title: title,
      description: description,
      sourceName: sourceName,
      sourceType: sourceType,
      cardCount: 0,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a flashcard deck from JSON
  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      sourceName: json['source_name'] as String?,
      sourceType: json['source_type'] as String?,
      cardCount: json['card_count'] as int? ?? 0,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert flashcard deck to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source_name': sourceName,
      'source_type': sourceType,
      'card_count': cardCount,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this flashcard deck with the given values
  FlashcardDeck copyWith({
    String? id,
    String? title,
    String? description,
    String? sourceName,
    String? sourceType,
    int? cardCount,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      cardCount: cardCount ?? this.cardCount,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for a flashcard
class Flashcard {
  /// Flashcard ID
  final String id;

  /// Deck ID this flashcard belongs to
  final String deckId;

  /// Question on the front of the card
  final String question;

  /// Answer on the back of the card
  final String answer;

  /// Optional hint for the flashcard
  final String? hint;

  /// When the card was last reviewed
  final DateTime? lastReviewedAt;

  /// When the card should be reviewed next (for spaced repetition)
  final DateTime? nextReviewDate;

  /// Ease factor for spaced repetition algorithm
  final double easeFactor;

  /// Interval for spaced repetition algorithm
  final int interval;

  /// Number of times the card has been reviewed
  final int reviewCount;

  /// Created at timestamp
  final DateTime createdAt;

  /// Updated at timestamp
  final DateTime? updatedAt;

  /// Flashcard Constructor
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.hint,
    this.lastReviewedAt,
    this.nextReviewDate,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a new flashcard
  factory Flashcard.create({
    required String deckId,
    required String question,
    required String answer,
    String? hint,
  }) {
    final now = DateTime.now();
    return Flashcard(
      id: const Uuid().v4(),
      deckId: deckId,
      question: question,
      answer: answer,
      hint: hint,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a flashcard from JSON
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      hint: json['hint'] as String?,
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.parse(json['last_reviewed_at'] as String)
          : null,
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.parse(json['next_review_date'] as String)
          : null,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      interval: json['interval'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert flashcard to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'question': question,
      'answer': answer,
      'hint': hint,
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'next_review_date': nextReviewDate?.toIso8601String(),
      'ease_factor': easeFactor,
      'interval': interval,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this flashcard with the given values
  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    String? hint,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    double? easeFactor,
    int? interval,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      hint: hint ?? this.hint,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
