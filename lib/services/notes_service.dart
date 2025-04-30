import 'package:deltamind/models/note.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Service for managing notes
class NotesService {
  /// Get all notes for the current user
  static Future<List<Note>> getUserNotes({
    String? searchQuery,
    List<String>? tags,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query = SupabaseService.client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%${searchQuery}%,content.ilike.%${searchQuery}%',
        );
      }

      if (tags != null && tags.isNotEmpty) {
        // Filter by any of the tags using the PostgreSQL array overlap operator
        query = query.overlaps('tags', tags);
      }

      // Order by pinned first, then by most recently updated
      final finalQuery = query
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      final response = await finalQuery;

      return (response as List).map((note) => Note.fromJson(note)).toList();
    } catch (e) {
      debugPrint('Error getting user notes: $e');
      rethrow;
    }
  }

  /// Get a note by ID
  static Future<Note> getNoteById(String noteId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('notes')
          .select()
          .eq('id', noteId)
          .eq('user_id', userId)
          .single();

      return Note.fromJson(response);
    } catch (e) {
      debugPrint('Error getting note by ID: $e');
      rethrow;
    }
  }

  /// Create a new note
  static Future<Note> createNote({
    required String title,
    String? content,
    List<String>? tags,
    String? color,
    bool isPinned = false,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> noteData = {
        'user_id': userId,
        'title': title,
        'content': content,
        'tags': tags ?? [],
        'color': color,
        'is_pinned': isPinned,
      };

      final response = await SupabaseService.client
          .from('notes')
          .insert(noteData)
          .select()
          .single();

      return Note.fromJson(response);
    } catch (e) {
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  /// Update a note
  static Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
    List<String>? tags,
    String? color,
    bool? isPinned,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Build update data
      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (tags != null) updateData['tags'] = tags;
      if (color != null) updateData['color'] = color;
      if (isPinned != null) updateData['is_pinned'] = isPinned;

      // Always update the updated_at timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await SupabaseService.client
          .from('notes')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Note.fromJson(response);
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  /// Delete a note (soft delete)
  static Future<void> deleteNote(String id) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseService.client
          .from('notes')
          .update({'is_deleted': true})
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  /// Get all unique tags for the current user
  static Future<List<String>> getUserTags() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all notes for the user
      final response = await SupabaseService.client
          .from('notes')
          .select('tags')
          .eq('user_id', userId)
          .eq('is_deleted', false);

      // Extract unique tags
      final Set<String> uniqueTags = {};
      for (final note in response) {
        final tags = note['tags'] as List?;
        if (tags != null) {
          for (final tag in tags) {
            uniqueTags.add(tag.toString());
          }
        }
      }

      return uniqueTags.toList()..sort();
    } catch (e) {
      debugPrint('Error getting user tags: $e');
      return [];
    }
  }
}
