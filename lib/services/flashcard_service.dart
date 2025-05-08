import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:deltamind/models/flashcard.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

/// Service for managing flashcards
class FlashcardService {
  /// Create a new flashcard deck
  static Future<FlashcardDeck> createDeck({
    required String title,
    String? description,
    String? sourceName,
    String? sourceType,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final deckData = {
        'title': title,
        'description': description,
        'source_name': sourceName,
        'source_type': sourceType,
        'card_count': 0,
        'user_id': userId,
      };

      final response = await SupabaseService.client
          .from('flashcard_decks')
          .insert(deckData)
          .select()
          .single();

      return FlashcardDeck.fromJson(response);
    } catch (e) {
      debugPrint('Error creating flashcard deck: $e');
      rethrow;
    }
  }

  /// Get all flashcard decks for the current user
  static Future<List<FlashcardDeck>> getUserDecks() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('flashcard_decks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((deck) => FlashcardDeck.fromJson(deck))
          .toList();
    } catch (e) {
      debugPrint('Error getting user flashcard decks: $e');
      rethrow;
    }
  }

  /// Get a flashcard deck by ID
  static Future<FlashcardDeck> getDeckById(String deckId) async {
    try {
      final response = await SupabaseService.client
          .from('flashcard_decks')
          .select()
          .eq('id', deckId)
          .single();

      return FlashcardDeck.fromJson(response);
    } catch (e) {
      debugPrint('Error getting flashcard deck: $e');
      rethrow;
    }
  }

  /// Update a flashcard deck
  static Future<FlashcardDeck> updateDeck({
    required String deckId,
    String? title,
    String? description,
  }) async {
    try {
      final updateData = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('flashcard_decks')
          .update(updateData)
          .eq('id', deckId)
          .select()
          .single();

      return FlashcardDeck.fromJson(response);
    } catch (e) {
      debugPrint('Error updating flashcard deck: $e');
      rethrow;
    }
  }

  /// Delete a flashcard deck
  static Future<void> deleteDeck(String deckId) async {
    try {
      await SupabaseService.client
          .from('flashcard_decks')
          .delete()
          .eq('id', deckId);
    } catch (e) {
      debugPrint('Error deleting flashcard deck: $e');
      rethrow;
    }
  }

  /// Create a new flashcard
  static Future<Flashcard> createFlashcard({
    required String deckId,
    required String question,
    required String answer,
    String? hint,
  }) async {
    try {
      final flashcardData = {
        'deck_id': deckId,
        'question': question,
        'answer': answer,
        'hint': hint,
      };

      final response = await SupabaseService.client
          .from('flashcards')
          .insert(flashcardData)
          .select()
          .single();

      // Update card count in the deck
      await _updateDeckCardCount(deckId);

      return Flashcard.fromJson(response);
    } catch (e) {
      debugPrint('Error creating flashcard: $e');
      rethrow;
    }
  }

  /// Create multiple flashcards at once
  static Future<List<Flashcard>> createFlashcards({
    required String deckId,
    required List<Map<String, String>> cards,
  }) async {
    try {
      if (cards.isEmpty) {
        return [];
      }

      final flashcardsData = cards
          .map((card) => {
                'deck_id': deckId,
                'question': card['question'] ?? '',
                'answer': card['answer'] ?? '',
                'hint': card['hint'],
              })
          .toList();

      final response = await SupabaseService.client
          .from('flashcards')
          .insert(flashcardsData)
          .select();

      // Update card count in the deck
      await _updateDeckCardCount(deckId);

      return (response as List)
          .map((flashcard) => Flashcard.fromJson(flashcard))
          .toList();
    } catch (e) {
      debugPrint('Error creating multiple flashcards: $e');
      rethrow;
    }
  }

  /// Get all flashcards for a deck
  static Future<List<Flashcard>> getFlashcardsForDeck(String deckId) async {
    try {
      final response = await SupabaseService.client
          .from('flashcards')
          .select()
          .eq('deck_id', deckId)
          .order('created_at');

      return (response as List)
          .map((flashcard) => Flashcard.fromJson(flashcard))
          .toList();
    } catch (e) {
      debugPrint('Error getting flashcards for deck: $e');
      rethrow;
    }
  }

  /// Update a flashcard
  static Future<Flashcard> updateFlashcard({
    required String flashcardId,
    String? question,
    String? answer,
    String? hint,
  }) async {
    try {
      final updateData = {
        if (question != null) 'question': question,
        if (answer != null) 'answer': answer,
        if (hint != null) 'hint': hint,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('flashcards')
          .update(updateData)
          .eq('id', flashcardId)
          .select()
          .single();

      return Flashcard.fromJson(response);
    } catch (e) {
      debugPrint('Error updating flashcard: $e');
      rethrow;
    }
  }

  /// Delete a flashcard
  static Future<void> deleteFlashcard(String flashcardId) async {
    try {
      // Get the deck ID before deleting
      final flashcard = await SupabaseService.client
          .from('flashcards')
          .select('deck_id')
          .eq('id', flashcardId)
          .single();

      final deckId = flashcard['deck_id'] as String;

      // Delete the flashcard
      await SupabaseService.client
          .from('flashcards')
          .delete()
          .eq('id', flashcardId);

      // Update card count in the deck
      await _updateDeckCardCount(deckId);
    } catch (e) {
      debugPrint('Error deleting flashcard: $e');
      rethrow;
    }
  }

  /// Update flashcard review data after a review session
  static Future<void> updateFlashcardReview({
    required String flashcardId,
    required int quality, // 0-5 rating of recall quality
    required int interval, // New interval in days
    required double easeFactor, // New ease factor
  }) async {
    try {
      final now = DateTime.now();
      final nextReviewDate = DateTime(
        now.year,
        now.month,
        now.day + interval,
      );

      final updateData = {
        'last_reviewed_at': now.toIso8601String(),
        'next_review_date': nextReviewDate.toIso8601String(),
        'ease_factor': easeFactor,
        'interval': interval,
        'review_count': {'increment': 1},
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.client
          .from('flashcards')
          .update(updateData)
          .eq('id', flashcardId);
    } catch (e) {
      debugPrint('Error updating flashcard review: $e');
      rethrow;
    }
  }

  /// Update card count in the deck
  static Future<void> _updateDeckCardCount(String deckId) async {
    try {
      // Get count of flashcards in the deck
      final response = await SupabaseService.client
          .from('flashcards')
          .select()
          .eq('deck_id', deckId);

      final count = (response as List).length;

      // Update deck with new count
      await SupabaseService.client.from('flashcard_decks').update({
        'card_count': count,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deckId);
    } catch (e) {
      debugPrint('Error updating deck card count: $e');
      // Don't rethrow - this is an internal operation
    }
  }

  /// Generate flashcards from file content
  static Future<List<Map<String, String>>> generateFlashcardsFromContent(
    String content,
    int cardCount,
  ) async {
    try {
      final prompt = '''
Generate $cardCount flashcards based on the following educational content:

$content

Format the output in JSON like this:
{
  "flashcards": [
    {
      "question": "Front of card with a clear question",
      "answer": "Back of card with a comprehensive answer", 
      "hint": "Optional hint to help recall (if relevant)"
    }
  ]
}

Guidelines:
- Focus on key concepts, definitions, and important facts
- Questions should be clear and specific
- Answers should be comprehensive but concise
- Include hints only when they add value
- Cover different topics from the content
- Ensure questions test understanding, not just memorization

Important: Return only valid JSON, do not include any markdown formatting.
''';

      final response = await GeminiService.model.generateContent([
        Content.text(prompt),
      ]);

      final result = response.text;

      if (result == null || result.isEmpty) {
        throw Exception('Failed to generate flashcards: Empty response');
      }

      String processedResult = result;

      // Process the response to extract JSON
      if (result.contains('```json')) {
        final startMarker = '```json';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
        }
      } else if (result.contains('```')) {
        final startMarker = '```';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
        }
      }

      // Trim any whitespace
      processedResult = processedResult.trim();

      // Ensure we have valid JSON
      try {
        final firstBrace = processedResult.indexOf('{');
        final lastBrace = processedResult.lastIndexOf('}');

        if (firstBrace >= 0 && lastBrace >= 0 && firstBrace < lastBrace) {
          processedResult =
              processedResult.substring(firstBrace, lastBrace + 1);
        }

        final jsonData = jsonDecode(processedResult);
        final flashcards = jsonData['flashcards'] as List;

        return flashcards
            .map<Map<String, String>>((flashcard) => {
                  'question': flashcard['question'] as String,
                  'answer': flashcard['answer'] as String,
                  'hint': (flashcard['hint'] as String?) ?? '',
                })
            .toList();
      } catch (e) {
        debugPrint('Error processing AI response: $e');
        throw Exception('Failed to process AI response: $e');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }

  /// Extract text from a PDF file
  static Future<String> extractTextFromPdf(File? file, Uint8List? bytes) async {
    try {
      // Load the PDF document
      final Uint8List pdfBytes;
      if (file != null) {
        pdfBytes = await file.readAsBytes();
      } else if (bytes != null) {
        pdfBytes = bytes;
      } else {
        throw Exception('No file or bytes provided for PDF extraction');
      }

      final document = PdfDocument(inputBytes: pdfBytes);

      // Create a PDF text extractor to extract text
      final extractor = PdfTextExtractor(document);

      // Extract text from all pages
      final pageCount = document.pages.count;
      final buffer = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        buffer.write(text);
        buffer.write('\n\n');
      }

      // Dispose the document
      document.dispose();

      return buffer.toString();
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from various file types
  static Future<String> extractTextFromFile(
      {File? file, Uint8List? bytes, required String fileType}) async {
    try {
      if (fileType.toLowerCase().contains('pdf')) {
        return await extractTextFromPdf(file, bytes);
      } else if (fileType.toLowerCase().contains('txt') ||
          fileType.toLowerCase().contains('doc') ||
          fileType.toLowerCase().contains('docx')) {
        // For text files
        if (file != null) {
          return await file.readAsString();
        } else if (bytes != null) {
          // Convert bytes to string for text files
          return utf8.decode(bytes);
        } else {
          throw Exception('No file or bytes provided for text extraction');
        }
      } else {
        throw Exception('Unsupported file type: $fileType');
      }
    } catch (e) {
      debugPrint('Error extracting text from file: $e');
      rethrow;
    }
  }

  /// Create flashcards from a file
  static Future<FlashcardDeck> createFlashcardsFromFile({
    File? file,
    Uint8List? fileBytes,
    required String fileName,
    required String fileType,
    required String title,
    String? description,
    int cardCount = 10,
  }) async {
    try {
      if (file == null && fileBytes == null) {
        throw Exception('No file or file bytes provided');
      }

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Extract text content from file
      final content = await extractTextFromFile(
          file: file, bytes: fileBytes, fileType: fileType);

      // Generate flashcards using AI
      final cards = await generateFlashcardsFromContent(content, cardCount);

      // Create a new deck
      final deck = await createDeck(
        title: title,
        description: description,
        sourceName: fileName,
        sourceType: fileType,
      );

      // Add flashcards to the deck
      await createFlashcards(deckId: deck.id, cards: cards);

      // Return the updated deck
      return await getDeckById(deck.id);
    } catch (e) {
      debugPrint('Error creating flashcards from file: $e');
      rethrow;
    }
  }
}
