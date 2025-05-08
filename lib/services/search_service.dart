import 'package:deltamind/models/note.dart';
import 'package:deltamind/models/flashcard.dart';
import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Search result item with metadata
class SearchResult {
  /// The unique ID of the item
  final String id;

  /// The title of the item
  final String title;

  /// Content preview or snippet
  final String? preview;

  /// Content type (note, quiz, flashcard)
  final SearchResultType type;

  /// When the item was created
  final DateTime? createdAt;

  /// When the item was last updated
  final DateTime? updatedAt;

  /// Additional metadata as needed
  final Map<String, dynamic>? metadata;

  /// Constructor
  const SearchResult({
    required this.id,
    required this.title,
    this.preview,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });
}

/// Type of search result
enum SearchResultType {
  /// Note
  note,

  /// Quiz
  quiz,

  /// Flashcard Deck
  flashcardDeck,

  /// Flashcard (individual card)
  flashcard,
}

/// Service for global search functionality
class SearchService {
  /// Search across all content types
  static Future<List<SearchResult>> searchAll(
    String query, {
    bool includeNotes = true,
    bool includeQuizzes = true,
    bool includeFlashcards = true,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      SupabaseService.checkAuthentication();
      final userId = SupabaseService.currentUser?.id;

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      List<SearchResult> results = [];
      List<Future<List<SearchResult>>> searchFutures = [];

      // Create search futures
      if (includeNotes) {
        searchFutures.add(_searchNotes(query, userId));
      }

      if (includeQuizzes) {
        searchFutures.add(_searchQuizzes(query, userId));
      }

      if (includeFlashcards) {
        searchFutures.add(_searchFlashcards(query, userId));
      }

      // Wait for all futures to complete
      final searchResults = await Future.wait(searchFutures);

      // Combine all results
      for (var resultList in searchResults) {
        results.addAll(resultList);
      }

      // Sort by relevance (currently sorting by date)
      results.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // Most recent first
      });

      return results;
    } catch (e) {
      debugPrint('Error during search: $e');
      rethrow;
    }
  }

  /// Search notes
  static Future<List<SearchResult>> _searchNotes(
      String query, String userId) async {
    try {
      final response = await SupabaseService.client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('updated_at', ascending: false);

      if (response == null) {
        return [];
      }

      return (response as List).map((json) {
        final note = Note.fromJson(json);
        String? preview;

        // Create a preview from content if it matches the query
        if (note.content != null && note.content!.isNotEmpty) {
          final content = note.content!;
          if (content.toLowerCase().contains(query.toLowerCase())) {
            final start = content.toLowerCase().indexOf(query.toLowerCase());
            final previewStart = start > 30 ? start - 30 : 0;
            final previewEnd = start + query.length + 50 < content.length
                ? start + query.length + 50
                : content.length;
            preview = '...${content.substring(previewStart, previewEnd)}...';
          } else {
            // If no match, take the first bit of content
            preview = content.length > 100
                ? '${content.substring(0, 100)}...'
                : content;
          }
        }

        return SearchResult(
          id: note.id,
          title: note.title,
          preview: preview,
          type: SearchResultType.note,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          metadata: {
            'color': note.color,
            'isPinned': note.isPinned,
            'tags': note.tags ?? [],
          },
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching notes: $e');
      return [];
    }
  }

  /// Search quizzes
  static Future<List<SearchResult>> _searchQuizzes(
      String query, String userId) async {
    try {
      final response = await SupabaseService.client
          .from('quizzes')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('updated_at', ascending: false);

      if (response == null) {
        return [];
      }

      // Search in quiz questions as well
      final questionsResponse = await SupabaseService.client
          .from('questions')
          .select('*, quizzes!inner(*)')
          .eq('quizzes.user_id', userId)
          .or('question_text.ilike.%$query%,explanation.ilike.%$query%');

      // Build results from quizzes
      List<SearchResult> results = (response as List).map((json) {
        final quiz = Quiz.fromJson(json);
        return SearchResult(
          id: quiz.id,
          title: quiz.title,
          preview: quiz.description,
          type: SearchResultType.quiz,
          createdAt: quiz.createdAt,
          updatedAt: quiz.updatedAt,
          metadata: {
            'quizType': quiz.quizType,
            'difficulty': quiz.difficulty,
          },
        );
      }).toList();

      // Add results from questions (ensuring no duplicates)
      if (questionsResponse != null) {
        Set<String> addedQuizIds = results.map((r) => r.id).toSet();

        for (var questionData in questionsResponse) {
          final quizData = questionData['quizzes'];
          if (quizData == null) continue;

          final String quizId = quizData['id'];
          if (quizId == null) continue;

          // Skip if we already have this quiz in results
          if (addedQuizIds.contains(quizId)) continue;
          addedQuizIds.add(quizId);

          final question = questionData['question_text'] ?? 'Unknown question';
          final quiz = Quiz.fromJson(quizData);

          results.add(SearchResult(
            id: quiz.id,
            title: quiz.title,
            preview: 'Contains question: $question',
            type: SearchResultType.quiz,
            createdAt: quiz.createdAt,
            updatedAt: quiz.updatedAt,
            metadata: {
              'quizType': quiz.quizType,
              'difficulty': quiz.difficulty,
            },
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching quizzes: $e');
      return [];
    }
  }

  /// Search flashcards
  static Future<List<SearchResult>> _searchFlashcards(
      String query, String userId) async {
    try {
      List<SearchResult> results = [];

      // Search flashcard decks
      final decksResponse = await SupabaseService.client
          .from('flashcard_decks')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('updated_at', ascending: false);

      if (decksResponse != null) {
        // Add deck results
        results.addAll((decksResponse as List).map((json) {
          final deck = FlashcardDeck.fromJson(json);
          return SearchResult(
            id: deck.id,
            title: deck.title,
            preview: deck.description,
            type: SearchResultType.flashcardDeck,
            createdAt: deck.createdAt,
            updatedAt: deck.updatedAt,
            metadata: {
              'cardCount': deck.cardCount,
            },
          );
        }));
      }

      // Search individual flashcards
      final cardsResponse = await SupabaseService.client
          .from('flashcards')
          .select('*, flashcard_decks!inner(*)')
          .eq('flashcard_decks.user_id', userId)
          .or('question.ilike.%$query%,answer.ilike.%$query%,hint.ilike.%$query%');

      if (cardsResponse != null) {
        // Track which decks we've already added from the card search
        Set<String> addedDeckIds = results.map((r) => r.id).toSet();

        // Group cards by deck for better organization
        Map<String, List<Map<String, dynamic>>> cardsByDeck = {};

        for (var cardData in cardsResponse) {
          final deckId = cardData['deck_id'];
          if (deckId == null) continue;

          if (!cardsByDeck.containsKey(deckId)) {
            cardsByDeck[deckId] = [];
          }
          cardsByDeck[deckId]!.add(cardData);
        }

        // Add results grouped by deck
        for (var entry in cardsByDeck.entries) {
          final deckId = entry.key;
          final cards = entry.value;
          if (cards.isEmpty) continue;

          final deckData = cards.first['flashcard_decks'];
          if (deckData == null) continue;

          // Skip if we already added this deck
          if (addedDeckIds.contains(deckId)) continue;
          addedDeckIds.add(deckId);

          final deck = FlashcardDeck.fromJson(deckData);

          // Create a preview mentioning the matching cards
          final question = cards.first['question'] ?? 'Unknown';
          final previewText = 'Contains flashcards: "$question"'
              '${cards.length > 1 ? ' and ${cards.length - 1} more' : ''}';

          results.add(SearchResult(
            id: deck.id,
            title: deck.title,
            preview: previewText,
            type: SearchResultType.flashcardDeck,
            createdAt: deck.createdAt,
            updatedAt: deck.updatedAt,
            metadata: {
              'cardCount': deck.cardCount,
              'matchingCardCount': cards.length,
            },
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching flashcards: $e');
      return [];
    }
  }
}
