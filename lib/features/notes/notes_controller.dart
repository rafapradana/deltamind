import 'package:deltamind/models/note.dart';
import 'package:deltamind/services/notes_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for notes
class NotesState {
  /// List of notes
  final List<Note> notes;

  /// Whether the notes are loading
  final bool isLoading;

  /// Error message if loading failed
  final String? errorMessage;

  /// Search query
  final String searchQuery;

  /// Selected tags
  final List<String> selectedTags;

  /// All available tags
  final List<String> availableTags;

  /// View type (grid or list)
  final bool isGridView;

  /// Create notes state with the given parameters
  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedTags = const [],
    this.availableTags = const [],
    this.isGridView = true,
  });

  /// Create a copy of this state with the given values
  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    List<String>? selectedTags,
    List<String>? availableTags,
    bool? isGridView,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      availableTags: availableTags ?? this.availableTags,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  /// Get filtered notes with proper sorting (pinned notes first)
  List<Note> get filteredNotes {
    // Sort notes - pinned first, then by updated date
    final filteredList = List<Note>.from(notes);
    filteredList.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;

      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate); // Newer first
    });

    return filteredList;
  }
}

/// Controller for notes
class NotesController extends StateNotifier<NotesState> {
  /// Create a notes controller
  NotesController(this.ref) : super(const NotesState());

  /// Reference to the provider scope
  final Ref ref;

  /// Load notes from the database
  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final notes = await NotesService.getUserNotes(
        searchQuery: state.searchQuery,
        tags: state.selectedTags.isNotEmpty ? state.selectedTags : null,
      );

      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      debugPrint('Error loading notes: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notes: $e',
      );
    }
  }

  /// Get a note by its ID
  Future<Note?> getNoteById(String id) async {
    try {
      return await NotesService.getNoteById(id);
    } catch (e) {
      debugPrint('Error getting note by ID: $e');
      state = state.copyWith(errorMessage: 'Failed to get note: $e');
      return null;
    }
  }

  /// Load tags from the database
  Future<void> loadTags() async {
    try {
      final tags = await NotesService.getUserTags();
      state = state.copyWith(availableTags: tags);
    } catch (e) {
      debugPrint('Error loading tags: $e');
    }
  }

  /// Create a new note
  Future<Note?> createNote(Note note) async {
    try {
      final createdNote = await NotesService.createNote(
        title: note.title,
        content: note.content,
        tags: note.tags,
        color: note.color,
        isPinned: note.isPinned,
      );

      // Refresh the notes list
      await loadNotes();

      // Refresh tags if new tags were added
      if (note.tags.isNotEmpty) {
        await loadTags();
      }

      return createdNote;
    } catch (e) {
      debugPrint('Error creating note: $e');
      state = state.copyWith(errorMessage: 'Failed to create note: $e');
      return null;
    }
  }

  /// Update a note
  Future<Note?> updateNote(Note note) async {
    try {
      final updatedNote = await NotesService.updateNote(
        id: note.id,
        title: note.title,
        content: note.content,
        tags: note.tags,
        color: note.color,
        isPinned: note.isPinned,
      );

      // Refresh the notes list
      await loadNotes();

      // Refresh tags if tags were changed
      await loadTags();

      return updatedNote;
    } catch (e) {
      debugPrint('Error updating note: $e');
      state = state.copyWith(errorMessage: 'Failed to update note: $e');
      return null;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String id) async {
    try {
      await NotesService.deleteNote(id);

      // Remove the note from the state
      final updatedNotes = state.notes.where((note) => note.id != id).toList();
      state = state.copyWith(notes: updatedNotes);

      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      state = state.copyWith(errorMessage: 'Failed to delete note: $e');
      return false;
    }
  }

  /// Toggle view type between grid and list
  void toggleViewType() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  /// Toggle pin status of a note
  Future<void> togglePin(String noteId) async {
    try {
      // Find the note in state
      final index = state.notes.indexWhere((note) => note.id == noteId);
      if (index == -1) return;

      final note = state.notes[index];
      final updatedNote = await NotesService.updateNote(
        id: noteId,
        isPinned: !note.isPinned,
      );

      if (updatedNote != null) {
        final notesCopy = List<Note>.from(state.notes);
        notesCopy[index] = updatedNote;
        state = state.copyWith(notes: notesCopy);
      }
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  /// Update a note's color
  Future<void> updateNoteColor(String noteId, String? color) async {
    try {
      final index = state.notes.indexWhere((note) => note.id == noteId);
      if (index == -1) return;

      final updatedNote = await NotesService.updateNote(
        id: noteId,
        color: color,
      );

      if (updatedNote != null) {
        final notesCopy = List<Note>.from(state.notes);
        notesCopy[index] = updatedNote;
        state = state.copyWith(notes: notesCopy);
      }
    } catch (e) {
      debugPrint('Error updating note color: $e');
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Toggle tag selection
  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  /// Add a tag to selected tags
  void addSelectedTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (!tags.contains(tag)) {
      tags.add(tag);
      state = state.copyWith(selectedTags: tags);
    }
  }

  /// Remove a tag from selected tags
  void removeSelectedTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
      state = state.copyWith(selectedTags: tags);
    }
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedTags: [],
    );
  }
}

/// Provider for notes controller
final notesControllerProvider =
    StateNotifierProvider<NotesController, NotesState>((ref) {
  return NotesController(ref);
});

/// Provider for current view type (grid/list)
final viewTypeProvider = Provider<bool>((ref) {
  return ref.watch(notesControllerProvider).isGridView;
});
