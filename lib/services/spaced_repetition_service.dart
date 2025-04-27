import 'package:deltamind/services/quiz_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Model class for SpacedRepetition
class SpacedRepetition {
  final String id;
  final String userId;
  final String questionId;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final double easeFactor;
  final int interval;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SpacedRepetition({
    required this.id,
    required this.userId,
    required this.questionId,
    this.lastReviewed,
    this.nextReview,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SpacedRepetition.fromJson(Map<String, dynamic> json) {
    return SpacedRepetition(
      id: json['id'],
      userId: json['user_id'],
      questionId: json['question_id'],
      lastReviewed: json['last_reviewed'] != null
          ? DateTime.parse(json['last_reviewed'])
          : null,
      nextReview: json['next_review'] != null
          ? DateTime.parse(json['next_review'])
          : null,
      easeFactor: json['ease_factor'] ?? 2.5,
      interval: json['interval'] ?? 1,
      reviewCount: json['review_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'last_reviewed': lastReviewed?.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'ease_factor': easeFactor,
      'interval': interval,
      'review_count': reviewCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  SpacedRepetition copyWith({
    String? id,
    String? userId,
    String? questionId,
    DateTime? lastReviewed,
    DateTime? nextReview,
    double? easeFactor,
    int? interval,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpacedRepetition(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service for managing spaced repetition
class SpacedRepetitionService {
  /// Add a question to spaced repetition
  static Future<SpacedRepetition> addToSpacedRepetition(String questionId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already exists
      final existing = await SupabaseService.client
          .from('spaced_repetition')
          .select()
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle();

      if (existing != null) {
        return SpacedRepetition.fromJson(existing);
      }

      final now = DateTime.now();
      final nextReview = now.add(const Duration(days: 1));

      final data = {
        'user_id': userId,
        'question_id': questionId,
        'last_reviewed': now.toIso8601String(),
        'next_review': nextReview.toIso8601String(),
        'ease_factor': 2.5,
        'interval': 1,
        'review_count': 0,
      };

      final response = await SupabaseService.client
          .from('spaced_repetition')
          .insert(data)
          .select()
          .single();

      return SpacedRepetition.fromJson(response);
    } catch (e) {
      debugPrint('Error adding to spaced repetition: $e');
      rethrow;
    }
  }

  /// Get due questions for spaced repetition
  static Future<List<Question>> getDueQuestions({int limit = 10}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toIso8601String();

      final response = await SupabaseService.client
          .from('spaced_repetition')
          .select('question_id')
          .eq('user_id', userId)
          .lte('next_review', now)
          .limit(limit);

      if (response.isEmpty) {
        return [];
      }

      final questionIds = (response as List)
          .map((item) => item['question_id'] as String)
          .toList();

      final questions = await SupabaseService.client
          .from('questions')
          .select()
          .inFilter('id', questionIds);

      return (questions as List)
          .map((question) => Question.fromJson(question))
          .toList();
    } catch (e) {
      debugPrint('Error getting due questions: $e');
      rethrow;
    }
  }

  /// Update spaced repetition after review
  /// [quality] is a rating between 0-5:
  /// 0: Complete blackout, didn't recognize the question
  /// 1: Incorrect response, but recognized the question
  /// 2: Incorrect response, but the correct answer felt familiar
  /// 3: Correct response, but required significant effort
  /// 4: Correct response, after some hesitation
  /// 5: Correct response, perfect recall
  static Future<SpacedRepetition> updateAfterReview(
    String questionId,
    int quality,
  ) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current data
      final current = await SupabaseService.client
          .from('spaced_repetition')
          .select()
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .single();

      final item = SpacedRepetition.fromJson(current);

      // SuperMemo SM-2 algorithm implementation
      double newEaseFactor = item.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;

      int newInterval;
      if (quality < 3) {
        newInterval = 1; // Reset to 1 day for incorrect responses
      } else {
        if (item.reviewCount == 0) {
          newInterval = 1;
        } else if (item.reviewCount == 1) {
          newInterval = 6;
        } else {
          newInterval = (item.interval * newEaseFactor).round();
        }
      }

      final now = DateTime.now();
      final nextReview = now.add(Duration(days: newInterval));

      final newItem = item.copyWith(
        lastReviewed: now,
        nextReview: nextReview,
        easeFactor: newEaseFactor,
        interval: newInterval,
        reviewCount: item.reviewCount + 1,
        updatedAt: now,
      );

      // Update in database
      await SupabaseService.client
          .from('spaced_repetition')
          .update({
            'last_reviewed': newItem.lastReviewed?.toIso8601String(),
            'next_review': newItem.nextReview?.toIso8601String(),
            'ease_factor': newItem.easeFactor,
            'interval': newItem.interval,
            'review_count': newItem.reviewCount,
            'updated_at': newItem.updatedAt?.toIso8601String(),
          })
          .eq('id', item.id);

      return newItem;
    } catch (e) {
      debugPrint('Error updating spaced repetition: $e');
      rethrow;
    }
  }

  /// Get spaced repetition statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('spaced_repetition')
          .select('*')
          .eq('user_id', userId);

      final items = (response as List)
          .map((item) => SpacedRepetition.fromJson(item))
          .toList();

      final now = DateTime.now();
      
      // Calculate statistics
      final totalCards = items.length;
      final dueToday = items.where((item) => 
          item.nextReview != null && 
          item.nextReview!.isBefore(now.add(const Duration(days: 1)))).length;
      final dueTomorrow = items.where((item) => 
          item.nextReview != null && 
          item.nextReview!.isAfter(now.add(const Duration(days: 1))) &&
          item.nextReview!.isBefore(now.add(const Duration(days: 2)))).length;
      final dueNextWeek = items.where((item) => 
          item.nextReview != null && 
          item.nextReview!.isAfter(now.add(const Duration(days: 2))) &&
          item.nextReview!.isBefore(now.add(const Duration(days: 7)))).length;
      final averageEaseFactor = items.isEmpty ? 0.0 : 
          items.fold<double>(0, (sum, item) => sum + item.easeFactor) / items.length;
      final totalReviews = items.fold<int>(0, (sum, item) => sum + item.reviewCount);

      // Calculate mastered cards (cards with interval > 30 days)
      final mastered = items.where((item) => item.interval >= 30).length;

      return {
        'totalCards': totalCards,
        'dueToday': dueToday,
        'dueTomorrow': dueTomorrow,
        'dueNextWeek': dueNextWeek,
        'averageEaseFactor': averageEaseFactor,
        'totalReviews': totalReviews,
        'mastered': mastered,
      };
    } catch (e) {
      debugPrint('Error getting spaced repetition statistics: $e');
      rethrow;
    }
  }
  
  /// Get due cards with question details
  static Future<List<Map<String, dynamic>>> getDueCards({int limit = 20}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toIso8601String();
      
      // Get due spaced repetition items
      final response = await SupabaseService.client
          .from('spaced_repetition')
          .select('*, questions!inner(*, quiz_id)')
          .eq('user_id', userId)
          .lte('next_review', now)
          .limit(limit);
          
      if (response.isEmpty) {
        return [];
      }
      
      // Get quiz titles for the questions
      final cards = <Map<String, dynamic>>[];
      
      for (final item in response) {
        final question = item['questions'];
        final quizId = question['quiz_id'];
        
        final quizResponse = await SupabaseService.client
            .from('quizzes')
            .select('title')
            .eq('id', quizId)
            .single();
            
        cards.add({
          'id': item['id'],
          'questionId': item['question_id'],
          'question': question['question_text'],
          'options': question['options'],
          'correctAnswer': question['correct_answer'],
          'explanation': question['explanation'],
          'questionType': question['question_type'],
          'quizId': quizId,
          'quizTitle': quizResponse['title'],
          'nextReview': item['next_review'],
          'interval': item['interval'],
          'easeFactor': item['ease_factor'],
        });
      }
      
      return cards;
    } catch (e) {
      debugPrint('Error getting due cards: $e');
      // Return empty list instead of rethrowing to avoid app crashes
      return [];
    }
  }
} 